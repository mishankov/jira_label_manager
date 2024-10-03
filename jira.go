package main

import (
	"bytes"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

type Jira struct {
	baseUrl  string
	login    string
	password string
}

type JiraTask struct {
	key     string
	summary string
}

func (jt JiraTask) String() string {
	return fmt.Sprintf("%v - %q", jt.key, jt.summary)
}

type JiraTaskAction struct {
	isAdd    bool
	isRemove bool
}

func (jta JiraTaskAction) String() string {
	if jta.isAdd {
		return "add"
	}

	if jta.isRemove {
		return "remove"
	}

	return ""
}

type JiraTasksResponse struct {
	Issues []JiraTasksResponseIssue
	Total  int
}

type JiraTasksResponseIssue struct {
	Key    string
	Fields JiraTasksResponseIssueFields
}

type JiraTasksResponseIssueFields struct {
	Summary string
}

func (j Jira) getJiraTasksByJQL(jql string) ([]JiraTask, error) {
	url := j.baseUrl + "/rest/api/latest/search?jql=" + url.QueryEscape(jql)
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := http.Client{Transport: tr}
	req, err := http.NewRequest("GET", url, nil)

	if err != nil {
		return nil, err
	}

	req.Header.Add("Authorization", "Basic "+base64.StdEncoding.EncodeToString([]byte(j.login+":"+j.password)))
	req.Header.Add("Content-Type", "application/json")

	resp, err := client.Do(req)

	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 300 {
		return nil, errors.New("status is " + resp.Status)
	}

	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	var jiraResponse JiraTasksResponse

	err = json.Unmarshal(body, &jiraResponse)

	if err != nil {
		return nil, err
	}

	var result []JiraTask

	for _, issue := range jiraResponse.Issues {
		result = append(result, JiraTask{key: issue.Key, summary: issue.Fields.Summary})
	}

	return result, nil
}

func (j Jira) labelAction(taskKey string, action JiraTaskAction, label string) error {
	actionString := action.String()

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := http.Client{Transport: tr}
	req, err := http.NewRequest("PUT", j.baseUrl+"/rest/api/latest/issue/"+taskKey, bytes.NewBuffer([]byte(fmt.Sprintf(`{"update": {"labels": [{%q: %q}]}}`, actionString, label))))

	if err != nil {
		return err
	}

	req.Header.Add("Authorization", "Basic "+base64.StdEncoding.EncodeToString([]byte(j.login+":"+j.password)))
	req.Header.Add("Content-Type", "application/json")

	resp, err := client.Do(req)

	if err != nil {
		return err
	}

	if resp.StatusCode >= 300 {
		return errors.New("status is " + resp.Status)
	}

	return nil
}

func (j Jira) labelActionWrapper(task string, action JiraTaskAction, label string, ch chan error) error {
	fmt.Println("Removing label", label, "for task", task)
	err := j.labelAction(task, action, label)
	if err != nil {
		fmt.Println("Error:", err.Error())
	}

	ch <- err

	return err
}

func (j Jira) applyLabelChanges(tasks []JiraTask, labelsToRemove []string, labelsToAdd []string) {
	ch := make(chan error)
	for _, task := range tasks {
		for _, label := range labelsToRemove {
			label := strings.TrimSpace(label)
			if len(label) > 0 {
				go j.labelActionWrapper(task.key, JiraTaskAction{isRemove: true}, label, ch)
			}
		}

		for _, label := range labelsToAdd {
			label := strings.TrimSpace(label)
			if len(label) > 0 {
				go j.labelActionWrapper(task.key, JiraTaskAction{isAdd: true}, label, ch)
			}
		}
	}

	for err := range ch {
		fmt.Println(err)
	}
}
