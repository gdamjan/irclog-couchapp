module Helpers exposing (.. )

import Http exposing (encodeUri)
import Process
import Task
import Time exposing (Time)
import Dict

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

{-
    Send a message after a delay
-}
delay : Time -> msg -> Cmd msg
delay time msg =
  Process.sleep time
  |> Task.perform (\_ -> msg)

{-
    Group a list of items by a key.
    Supply an indexing function (eg. .id) and a list of items. groupWith returns a List of (key, sublist) tuples.
    The sublists will retain the order of the original list.
-}
groupWith : (a -> comparable) -> List a -> List ( comparable, List a )
groupWith group list =
    let alwaysCons a v = Just (a :: Maybe.withDefault [] v)
        makeGroups a = Dict.update (group a) (alwaysCons a)
    in
        List.foldr makeGroups Dict.empty list
        |> Dict.toList
