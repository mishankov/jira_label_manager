import json, strformat

import httpreq

type
  Jira* = object
    baseUrl*: string
    login*: string
    password*: string
    ignoreSsl*: bool

  JiraTask* = object
    key*: string
    summary*: string

  JiraTaskAction* = enum add, remove

proc getJiraTasks*(jira: Jira, jql: string): seq[JiraTask] =
  let response = get(
    url = jira.baseUrl & "/rest/api/latest/search",
    queryParams = {"jql": jql},
    headers = {"Content-Type": "application/json"},
    auth = (jira.login, jira.password),
    ignoreSsl = jira.ignoreSsl
  )

  if response.ok():
    let payloadJson = response.json()
    echo "Tasks for jql \"", jql, "\":"
    for issue in payloadJson["issues"]: 
      echo issue["key"].getStr(), " - ", issue["fields"]["summary"].getStr()
      result.add(JiraTask(key: issue["key"].getStr(), summary: issue["fields"]["summary"].getStr())) 

    return result
  else:
    echo fmt"Error: {response.status}, {response.body}"


proc labelAction*(jira: Jira, taskKey: string, action: JiraTaskAction, label: string) = 
  let response = put(
    url = jira.baseUrl & "/rest/api/latest/issue/" & taskKey,
    headers = {"Content-Type": "application/json"},
    body = $ %*{"update": {"labels": [{$action: label}]}},
    auth = (jira.login, jira.password),
    ignoreSsl = jira.ignoreSsl
  )

  if response.ok():
    echo fmt"Action: {action}, label: {label}, task: {taskKey}. Success"
  else:
    echo fmt"Action: {action}, label: {label}, task: {taskKey}. Fail. Status: {response.status}, body: {response.body}"
