import base64, strformat

proc basicAuthHeader*(login: string, password: string): string = 
  let strToEncode = login & ":" & password;
  return fmt"Basic {encode(strToEncode)}"
