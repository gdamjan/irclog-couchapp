module Channel exposing (..)

import Http
import Time
import Date
import Process
import Task
import Ports

import RemoteData

import Models exposing (..)
import Couch


getLast100 : String -> Cmd Msg
getLast100 channelName =
    Couch.getLast100Messages channelName
    |> Http.send (OnChannelViewResult channelName)

getAt : String -> Date.Date -> Cmd Msg
getAt channelName date =
    Couch.getAt channelName date
    |> Http.send (OnChannelViewResult channelName)

getPrevPage channel =
    case channel.messages of
        head::_ ->
            Couch.getPrevPage channel.channelName head
            |> Http.send (OnPrevPageResult channel.channelName head)
        [] -> Cmd.none

getNextPage channel =
    case List.reverse channel.messages of
        last::_ ->
            Couch.getNextPage channel.channelName last
            |> Http.send (OnNextPageResult channel.channelName last)
        [] -> Cmd.none

getChanges : String -> String -> Cmd Msg
getChanges channelName last_seq =
    Couch.getChanges channelName last_seq
    |> Http.send (OnChannelChanges channelName last_seq)

delayedGetChanges : Float -> String -> String -> Cmd Msg
delayedGetChanges delay channelName last_seq =
    Process.sleep (delay*Time.second)
    |> Task.andThen (\_ -> Http.toTask (Couch.getChanges channelName last_seq))
    |> Task.attempt (\result -> OnChannelChanges channelName last_seq result)

createChannel channelName viewResult =
    let messages = List.sortBy (\doc -> Date.toTime doc.timestamp) viewResult.rows
        last_seq = viewResult.last_seq
    in
        { channelName=channelName, messages=messages, last_seq=last_seq }

updateChannel channel changesResult =
    let results = List.sortBy (\doc -> Date.toTime doc.timestamp) changesResult.rows
        last_seq = changesResult.last_seq
        messages = channel.messages ++ results
    in
        { channel | messages=messages, last_seq=last_seq }


-- only update the model if, the request was made for the same channel name and last_seq in the model hasn't changed meanwhile
updateChanges channelName since changesResult model =
    case model.channelLog of
        RemoteData.Success channel ->
            if channel.last_seq == since && channel.channelName == channelName then
            let
                chan = updateChannel channel changesResult
                nextModel = { model | channelLog= RemoteData.Success chan }
                last_seq = changesResult.last_seq
            in
                if List.isEmpty changesResult.rows then
                    nextModel ! [ getChanges channelName last_seq ]
                else
                    nextModel ! [ getChanges channelName last_seq,
                                    Ports.flashTitle ["irclogs for #" ++ channelName, " --- ** --- "]
                                ]
            else
                (model, Cmd.none)
        _ ->
            (model, Cmd.none)

-- don't give up if the changes feed returns an error
errorChanges channelName since err model =
    case model.channelLog of
        RemoteData.Success channelLog ->
            if channelLog.last_seq == since && channelLog.channelName == channelName then
                (model, delayedGetChanges 5 channelName since)
            else
                (model, Cmd.none)
        _ ->
            (model, Cmd.none)

channelViewResult channelName viewResult model =
    let chan = createChannel channelName viewResult
        last_seq = viewResult.last_seq
        nextModel = { model | channelLog=RemoteData.Success chan }
    in
        case model.route of
            ChannelRoute _ ->
                (nextModel, Cmd.batch [ getChanges channelName last_seq,
                                Ports.flashTitle ["irclogs for #" ++ channelName, " --- ** --- "]
                            ])
            _ ->
                (nextModel, Cmd.none)

nextPage channelName last viewResult model =
    case model.channelLog of
        RemoteData.Success channel ->
            if channel.channelName == channelName && matchTail last channel.messages then
                case viewResult.rows of
                    [] ->
                        let nextModel = { model | route = ChannelRoute channelName }
                        in
                            (nextModel, getChanges channelName viewResult.last_seq)
                    rows ->
                        let messages = channel.messages ++ rows
                            chan = { channel | messages = messages }
                            nextModel = { model | channelLog=RemoteData.Success chan }
                        in
                            (nextModel, Cmd.none)
            else
                (model, Cmd.none)
        _ ->
            (model, Cmd.none)

prevPage channelName head viewResult model =
    case model.channelLog of
        RemoteData.Success channel ->
            if channel.channelName == channelName && matchHead head channel.messages then
                let rows = List.reverse viewResult.rows
                    messages = rows ++ channel.messages
                    chan = { channel | messages = messages }
                    nextModel = { model | channelLog=RemoteData.Success chan }
                in
                    (nextModel, Cmd.none)
            else
                (model, Cmd.none)
        _ ->
            (model, Cmd.none)

matchHead head list =
    case list of
        h::_ ->
            if h == head then True else False
        [] ->
            False

matchTail tail list =
    case List.reverse list of
        t::_ ->
            if t == tail then True else False
        [] ->
            False
