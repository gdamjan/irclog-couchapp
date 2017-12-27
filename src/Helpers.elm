module Helpers exposing (.. )

import Http exposing (encodeUri)
import Process
import Task
import Time

url : String -> List (String,String) -> String
url baseUrl args =
  case args of
    [] ->
        baseUrl
    _ ->
        baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)

queryPair : (String,String) -> String
queryPair (key,value) =
  queryEscape key ++ "=" ++ queryEscape value

queryEscape : String -> String
queryEscape string =
  String.join "+" (String.split "%20" (Http.encodeUri string))


delay : Time.Time -> msg -> Cmd msg
delay time msg =
  Process.sleep time
  |> Task.perform (\_ -> msg)
