module Couch exposing (..)

import Http

import Helpers exposing (url)
import Models exposing (..)


getLastMessages : String -> Int -> Cmd Msg
getLastMessages channel num =
  let
    startkey = "[\"" ++ channel ++ "\", {}]"
    endkey = "[\"" ++ channel ++ "\", 0]"
    viewUrl = url "https://irc.softver.org.mk/ddoc/_view/channel" [
        ("startkey", startkey),
        ("endkey", endkey),
        ("limit", toString num),
        ("include_docs", "true"),
        ("descending", "true"),
        ("update_seq", "true"),
        ("reduce", "false")
      ]
  in
    Http.send ChannelViewResult (Http.get viewUrl viewResultDecoder)

getLast100Messages channel =
  getLastMessages channel 100


getChanges : String -> String -> Cmd Msg
getChanges channel since =
  let
      changesUrl = url "https://irc.softver.org.mk/api/_changes" [
         ("feed","longpoll"),
         ("heartbeat", "30000"),
         ("include_docs", "true"),
         ("filter","log/channel"),
         ("channel", channel),
         ("since", since)
      ]
  in
    Http.send ChannelChanges (Http.get changesUrl viewResultDecoder)
