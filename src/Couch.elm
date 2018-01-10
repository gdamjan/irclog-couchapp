module Couch exposing (..)

import Http
import Time
import Json.Decode as Decode
import Date exposing (Date)

import Helpers exposing (url)
import Models exposing (..)


getChannelLog : String -> Int -> String -> String -> List (String, String) -> Http.Request ViewResult
getChannelLog channel limit start end args =
    let
        startkey = "[\"" ++ channel ++ "\"," ++ start ++ "]"
        endkey = "[\"" ++ channel ++ "\"," ++ end  ++ "]"
        query = [
            ("startkey", startkey),
            ("endkey", endkey),
            ("limit", toString limit),
            ("include_docs", "true"),
            ("update_seq", "true"),
            ("reduce", "false")
        ]
        viewUrl = url "https://irc.softver.org.mk/ddoc/_view/channel" (query ++ args)
    in
        Http.get viewUrl viewResultDecoder

getLastMessages : String -> Int -> Http.Request ViewResult
getLastMessages channel num =
    getChannelLog channel num "{}" "0" [("descending", "true")]


getLast100Messages : String -> Http.Request ViewResult
getLast100Messages channel =
    getLastMessages channel 100

getAt : String -> Date.Date -> Http.Request ViewResult
getAt channelName date =
    let start = (Date.toTime date) / 1000 |> toString
    in
        getChannelLog channelName 100 start "{}" [("descending", "false")]

getPrevPage : String -> IrcMessage -> Http.Request ViewResult
getPrevPage channelName message =
    let start = (Date.toTime message.timestamp) / 1000 |> toString
        limit = 100
    in
        getChannelLog channelName limit start "0" [("descending", "true")]

getNextPage : String -> IrcMessage -> Http.Request ViewResult
getNextPage channelName message =
    let start = (Date.toTime message.timestamp) / 1000 |> toString
        limit = 100
    in
        getChannelLog channelName limit start "{}" [("descending", "false"), ("startkey_docid", message.id), ("skip","1")]


getChanges : String -> String -> Http.Request ChangesResult
getChanges channel since =
    let
        timeout = 90
        changesUrl = url "https://irc.softver.org.mk/api/_changes" [
            ("feed","longpoll"),
            ("timeout", toString <| timeout * 1000),
            ("include_docs", "true"),
            ("filter","log/channel"),
            ("channel", channel),
            ("since", since)
        ]
    in
        Http.request {
            method = "GET",
            headers = [Http.header "Accept" "application/json"],
            url = changesUrl,
            body = Http.emptyBody,
            expect = Http.expectJson changesDecoder,
            timeout = Just (timeout * Time.second * 1.15),
            withCredentials = False
        }

getChannelList : Http.Request (List Channel)
getChannelList =
    let listUrl = url "https://irc.softver.org.mk/ddoc/_view/channel" [
            ("update_seq", "true"),
            ("reduce", "true"),
            ("group_level", "1")
        ]
    in
        Http.get listUrl channelListDecoder

-- Json decoder for the CouchDb responses

-- The Couch View result:
-- {"total_rows":717308,"offset":94922,"update_seq":"718435-…",
-- "rows":[
--  {"id":"6d29a29c16e5d50e0f9512b09392bd8f","key":["lugola",1513961232.4929347],"value":null,"doc":{"_id":"6d29a29c16e5d50e0f9512b09392bd8f","_rev":"1-26a95effe55022a5656c92b3c768b0cb","sender":"damjan","channel":"lugola","message":"и што е разлика меѓу type и type alias","timestamp":1513961232.4929347}},
--  {"id":"6d29a29c16e5d50e0f9512b09392b52a","key":["lugola",1513961220.2767942],"value":null,"doc":{"_id":"6d29a29c16e5d50e0f9512b09392b52a","_rev":"1-551157ee6d4bb25eb67eefb11ad4b7d1","sender":"damjan","channel":"lugola","message":"vnz|m: како се викаше дечкото со elm ? :)","timestamp":1513961220.2767942}},
--  {"id":"6d29a29c16e5d50e0f9512b09392b243","key":["lugola",1513961046.2759392],"value":null,"doc":{"_id":"6d29a29c16e5d50e0f9512b09392b243","_rev":"1-267b48cc1888eb0d5f54d5d5c9768676","sender":"damjan","channel":"lugola","message":"епа не ми влегло и ме нервира","timestamp":1513961046.2759392}},
--  {"id":"6d29a29c16e5d50e0f9512b09392a86c","key":["lugola",1513960810.5307088],"value":null,"doc":{"_id":"6d29a29c16e5d50e0f9512b09392a86c","_rev":"1-5ebe69edbd1061036a3a5672bfec9928","sender":"jgjorgji","channel":"lugola","message":"али мислим дека доста брзо влага у меморија поготово ако користиш само тоа и предходно/наредно","timestamp":1513960810.5307088}},
--  {"id":"6d29a29c16e5d50e0f9512b093929ed6","key":["lugola",1513960766.9897487],"value":null,"doc":{"_id":"6d29a29c16e5d50e0f9512b093929ed6","_rev":"1-c3ca8148366402bc3833041fdafb66fc","sender":"jgjorgji","channel":"lugola","message":"damjan: подеси си полесно ctrl+b или нешто такво, маус е lost cause на тмукс","timestamp":1513960766.9897487}}
-- ]}

viewResultDecoder : Decode.Decoder ViewResult
viewResultDecoder =
    Decode.map4 ViewResult
        (Decode.field "rows" rowsDecoder)
        (Decode.field "update_seq" Decode.string)
        (Decode.field "total_rows" Decode.int)
        (Decode.field "offset" Decode.int)

rowsDecoder : Decode.Decoder IrcMessages
rowsDecoder =
    Decode.list (Decode.field "doc" rowDecoder)
    |> Decode.map (List.filterMap identity)

rowDecoder : Decode.Decoder (Maybe IrcMessage)
rowDecoder =
    Decode.maybe
    <| Decode.map5 IrcMessage
        (Decode.field "_id" Decode.string)
        (Decode.field "timestamp" dateDecoder)
        (Decode.field "sender" Decode.string)
        (Decode.field "channel" Decode.string)
        (Decode.field "message" Decode.string)

dateDecoder : Decode.Decoder Date.Date
dateDecoder =
    Decode.map (\t -> Date.fromTime (t*1000)) Decode.float


-- The Couch changes result:
-- {"results":[
-- { "seq":"719223-…",
--    "id":"6d29a29c16e5d50e0f9512b093ab64f2","changes":[{"rev":"1-ac146ffbf72ca8fad345e5920f85c73d"}],
--   "doc":{"_id":"6d29a29c16e5d50e0f9512b093ab64f2","_rev":"1-ac146ffbf72ca8fad345e5920f85c73d","sender":"GitHub149","channel":"lugola","message":"irclog-couchapp\u000F/elm\u000F cad666e\u000F Дамјан Георгиевски\u000F: move the View in a separate file, add css, header, footer","timestamp":1514301930.75895}
-- },
-- { "seq":"719224-…",
--    "id":"6d29a29c16e5d50e0f9512b093ab5a41","changes":[{"rev":"1-695752bc8e65f12169d8dccf30c97bd6"}],
--   "doc":{"_id":"6d29a29c16e5d50e0f9512b093ab5a41","_rev":"1-695752bc8e65f12169d8dccf30c97bd6","sender":"GitHub149","channel":"lugola","message":"irclog-couchapp\u000F/elm\u000F 0855d7f\u000F Дамјан Георгиевски\u000F: timestamp in database is in seconds, Date.fromTime uses miliseconds","timestamp":1514301930.7455664}
-- }
-- ],
-- "last_seq":"719224-…","pending":0}

changesDecoder : Decode.Decoder ChangesResult
changesDecoder =
    Decode.map2 ChangesResult
        (Decode.field "results" rowsDecoder)
        (Decode.field "last_seq" Decode.string)

-- {"update_seq":"720750-…",
--  "rows":[
--       {"key":["lugola"],"value":617675},
--       {"key":["ubuntu-mk"],"value":414},
-- ]}

channelListDecoder : Decode.Decoder (List Channel)
channelListDecoder =
    Decode.field "rows" (Decode.list channelRowDecoder)

channelRowDecoder : Decode.Decoder Channel
channelRowDecoder =
    Decode.map2 Channel
        (Decode.field "key" (Decode.index 0 Decode.string))
        (Decode.field "value" (Decode.int))
