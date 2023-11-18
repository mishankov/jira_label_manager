import uri, httpclient, net, json, strformat

import httpreq

type
  Jira* = object
    baseUrl*: string
    login*: string
    password*: string
  JiraTask* = object
    key*: string
    summary*: string

proc getJiraTasks*(jira: Jira, jql: string): seq[JiraTask] =
  let 
    headers = { "Content-Type": "application/json", "Authorization": basicAuthHeader(jira.login, jira.password) }
    url = jira.baseUrl & "/rest/api/latest/search?" & encodeQuery({"jql": jql}, false)

  var client = newHttpClient(sslContext=newContext(verifyMode=CVerifyNone))
  client.headers = newHttpHeaders(headers)

  let response = client.request(url)
  client.close()

  let payloadJson = parseJson(response.body)
  echo "Tasks for jql \"", jql, "\":"
  for issue in payloadJson["issues"]: 
    echo issue["key"].getStr(), " - ", issue["fields"]["summary"].getStr()
    result.add(JiraTask(key: issue["key"].getStr(), summary: issue["fields"]["summary"].getStr())) 

  return result

proc removeLabelFromTask*(jira: Jira, taskKey: string, label: string) =
  let 
    headers = { "Content-Type": "application/json", "Authorization": basicAuthHeader(jira.login, jira.password) }
    url = jira.baseUrl & "/rest/api/latest/issue/" & taskKey
    body = %*{"update": {"labels": [{"remove": label}]}}

  var client = newHttpClient(sslContext=newContext(verifyMode=CVerifyNone))
  client.headers = newHttpHeaders(headers)

  let response = client.request(url, httpMethod = HttpPut, body = $body)
  client.close()

  echo fmt"Removed label {label} from {taskKey} {response.status} {response.body}"

proc addLabelToTask*(jira: Jira, taskKey: string, label: string) =
  let 
    headers = { "Content-Type": "application/json", "Authorization": basicAuthHeader(jira.login, jira.password) }
    url = jira.baseUrl & "/rest/api/latest/issue/" & taskKey
    body = %*{"update": {"labels": [{"add": label}]}}

  var client = newHttpClient(sslContext=newContext(verifyMode=CVerifyNone))
  client.headers = newHttpHeaders(headers)

  let response = client.request(url, httpMethod = HttpPut, body = $body)
  client.close()

  echo fmt"Added label {label} to {taskKey} {response.status} {response.body}"
