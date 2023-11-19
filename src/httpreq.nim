import base64, strformat, httpclient, net, json, uri

type
  BaiscAuth* = tuple[login: string, password: string]
  Header* = tuple[key: string, value: string]
  QueryParam* = tuple[key: string, value: string]

  Request* = object
    url*: string
    basicAuth*: BaiscAuth

  Response* = object
    body*: string


proc json*(response: Response): JsonNode = 
  return parseJson(response.body)


proc basicAuthHeader*(login: string, password: string): string = 
  let strToEncode = login & ":" & password;
  return fmt"Basic {encode(strToEncode)}"


proc get*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], auth: BaiscAuth = ("", ""), ignoreSsl = false): Response = 

  # Prepare client

  var client: HttpClient
  if ignoreSsl:
    client = newHttpClient(sslContext=newContext(verifyMode=CVerifyNone))
  else:
    client = newHttpClient()

  # Prepare headers

  var innerHeaders: seq[tuple[key: string, val: string]] = @[]

  for header in headers:
    innerHeaders.add((header.key, header.value))

  if auth.login != "" and auth.password != "":
    innerHeaders.add({"Authorization": basicAuthHeader(auth.login, auth.password)})

  if innerHeaders.len() > 0:
    client.headers = newHttpHeaders(innerHeaders)

  # Prepare url

  var innerUrl = url

  # Prepare query params
  if queryParams.len() > 0:
    innerUrl &= fmt"?{encodeQuery(queryParams, usePlus=false)}"

  # Make request

  let response = client.request(innerUrl)
  client.close()

  return Response(body: response.body)
