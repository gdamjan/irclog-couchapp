module Channel exposing (..)

import Http
import Time
import Date
import Task
import Ports
import Dom.Scroll
import RemoteData

import Models exposing (..)
import Couch
import Helpers exposing (delay, sortByTimestamp)


getLast100 : String -> Cmd Msg
getLast100 channelName =
    Couch.getLast100Messages channelName
    |> Http.toTask
    |> Task.map (\response -> {response | rows=sortByTimestamp response.rows})
    |> Task.attempt (OnChannelViewResult channelName)

getAt : String -> Date.Date -> Cmd Msg
getAt channelName date =
    Couch.getAt channelName date
    |> Http.toTask
    |> Task.map (\response -> {response | rows=sortByTimestamp response.rows})
    |> Task.attempt (OnChannelViewResult channelName)


getPrevPage channel =
    case channel.messages of
        head::_ ->
            Couch.getPrevPage channel.channelName head
            |> Http.toTask
            |> Task.map (\response -> {response | rows=List.reverse response.rows})
            |> Task.attempt (OnPrevPageResult channel.channelName head)
        [] -> Cmd.none

getNextPage channel =
    case List.reverse channel.messages of
        last::_ ->
            Couch.getNextPage channel.channelName last
            |> Http.send (OnNextPageResult channel.channelName last)
        [] -> Cmd.none


changesTask channelName last_seq =
    Couch.getChanges channelName last_seq
    |> Http.toTask
    |> Task.map (\response -> {response | rows=sortByTimestamp response.rows})

getChanges : String -> String -> Cmd Msg
getChanges channelName last_seq =
    changesTask channelName last_seq
    |> Task.attempt (OnChannelChanges channelName last_seq)

delayedGetChanges : Float -> String -> String -> Cmd Msg
delayedGetChanges time channelName last_seq =
    delay time (changesTask channelName last_seq)
    |> Task.attempt (OnChannelChanges channelName last_seq)

createChannel channelName viewResult =
    let messages = viewResult.rows
        last_seq = viewResult.last_seq
    in
        { channelName=channelName, messages=messages, last_seq=last_seq }

updateChannel channel changesResult =
    let last_seq = changesResult.last_seq
        messages = channel.messages ++ changesResult.rows
    in
        { channel | messages=messages, last_seq=last_seq }


-- only update the model if, the request was made for the same channel name and last_seq in the model hasn't changed meanwhile
updateChanges channelName since changesResult model =
    case model.channelLog of
        RemoteData.Success channel ->
            if channel.last_seq == since && channel.channelName == channelName then
            let
                chan = updateChannel channel changesResult
                nextModel = { model | channelLog=RemoteData.Success chan }
                last_seq = changesResult.last_seq
            in
                if List.isEmpty changesResult.rows then
                    nextModel ! [ getChanges channelName last_seq ]
                else
                    nextModel ! [ getChanges channelName last_seq,
                                    Ports.flashTitle ["irclogs for #" ++ channelName, " --- ** --- "],
                                    Task.attempt (\_ -> NoOp) (Dom.Scroll.toBottom "scrollme")
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
                (model, delayedGetChanges (5*Time.second) channelName since)
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
                let messages = viewResult.rows ++ channel.messages
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
