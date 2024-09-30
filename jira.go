package main

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
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

type JiraTaskAction struct {
	isAdd    bool
	isRemove bool
}

type JiraTasksResponse struct {
	issues []JiraTasksResponseIssue
}

type JiraTasksResponseIssue struct {
	key    string
	fields JiraTasksResponseIssueFields
}

type JiraTasksResponseIssueFields struct {
	summary string
}

func (j Jira) getJiraTasksByJQL(jql string) ([]JiraTask, error) {
	client := http.Client{}
	req, err := http.NewRequest("GET", j.baseUrl+"/rest/api/latest/search?jql"+jql, nil)

	if err != nil {
		return nil, err
	}

	req.Header.Add("Authorization", "Basic "+base64.StdEncoding.EncodeToString([]byte(j.login+":"+j.password)))

	resp, err := client.Do(req)

	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	var jiraResponse JiraTasksResponse

	json.NewDecoder(resp.Body).Decode(&jiraResponse)

	var result []JiraTask

	for _, issue := range jiraResponse.issues {
		result = append(result, JiraTask{key: issue.key, summary: issue.fields.summary})
	}

	return result, nil
}
