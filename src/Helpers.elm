module Helpers exposing (.. )

import Http exposing (encodeUri)
import Process
import Task
import Time exposing (Time)
import Dict
import Date

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

month : Date.Date -> Int
month d =
    -- tell me that elm is beautiful
    case Date.month d of
        Date.Jan -> 1
        Date.Feb -> 2
        Date.Mar -> 3
        Date.Apr -> 4
        Date.May -> 5
        Date.Jun -> 6
        Date.Jul -> 7
        Date.Aug -> 8
        Date.Sep -> 9
        Date.Oct -> 10
        Date.Nov -> 11
        Date.Dec -> 12

dateOf : Date.Date -> String
dateOf d =

        String.join "-"
        <| [ Date.year d |> toString,
             month d |> toString |> String.padLeft 2 '0',
             Date.day d |> toString |> String.padLeft 2 '0'
        ]

timeOf : Date.Date -> String
timeOf d =
    String.join ":" [
        Date.hour d |> toString |> String.padLeft 2 '0',
        Date.minute d |> toString |> String.padLeft 2 '0',
        Date.second d |> toString |> String.padLeft 2 '0'
    ]

datetimeOf : Date.Date -> String
datetimeOf d =
    dateOf d ++ "T" ++ timeOf d
