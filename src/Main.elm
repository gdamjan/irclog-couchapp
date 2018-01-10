module Main exposing (..)

import Navigation exposing (program, Location)
import Time
import Task
import Process
import Date
import Http
import RemoteData

import Views
import Couch
import Models exposing (..)
import Routing exposing (parseLocation)


getChanges : String -> String -> Cmd Msg
getChanges channelName last_seq =
    Couch.getChanges channelName last_seq
    |> Http.send (OnChannelChanges channelName last_seq)

delayedGetChanges : Float -> String -> String -> Cmd Msg
delayedGetChanges delay channelName last_seq =
    Process.sleep (delay*Time.second)
    |> Task.andThen (\_ -> Http.toTask (Couch.getChanges channelName last_seq))
    |> Task.attempt (\result -> OnChannelChanges channelName last_seq result)

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


update : Msg -> AppModel -> (AppModel, Cmd Msg)
update msg model =
    case msg of
        OnLocationChange location ->
            let route = parseLocation location
            in
                activateRoute model route

        OnChannelViewResult channelName (Ok viewResult) ->
            let chan = createChannel channelName viewResult
                last_seq = viewResult.last_seq
                nextModel = { model | channelLog=RemoteData.Success chan }
            in
                case model.route of
                    ChannelRoute _ ->
                        (nextModel, getChanges channelName last_seq)
                    _ ->
                        (nextModel, Cmd.none)

        OnChannelViewResult _ (Err _) -> (model, Cmd.none)

        OnNextPageResult channelName last (Ok viewResult) ->
            case model.channelLog of
                RemoteData.Success channel ->
                    case (channel.channelName, List.reverse channel.messages) of
                        (channelName, last::_) ->
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
                        (_, _) ->
                            (model, Cmd.none)
                _ ->
                    (model, Cmd.none)

        OnPrevPageResult channelName head (Ok viewResult) ->
            case model.channelLog of
                RemoteData.Success channel ->
                    case (channel.channelName, channel.messages) of
                        (channelName, head::_) ->
                            let rows = List.reverse viewResult.rows
                                messages = rows ++ channel.messages
                                chan = { channel | messages = messages }
                                nextModel = { model | channelLog=RemoteData.Success chan }
                            in
                                (nextModel, Cmd.none)
                        (_, _) ->
                            (model, Cmd.none)
                _ ->
                    (model, Cmd.none)

        OnPrevPageResult _ _ (Err _) -> (model, Cmd.none)
        OnNextPageResult _ _ (Err _) -> (model, Cmd.none)

        OnChannelChanges channelName since (Ok changesResult) ->
            -- only update the model if, the request was made for the same channel name and last_seq in the model hasn't changed meanwhile
            case model.channelLog of
                RemoteData.Success channel ->
                    if channel.last_seq == since && channel.channelName == channelName then
                    let
                        chan = updateChannel channel changesResult
                        nextModel = { model | channelLog= RemoteData.Success chan }
                        last_seq = changesResult.last_seq
                    in
                        (nextModel, getChanges channelName last_seq)
                    else
                        (model, Cmd.none)
                _ ->
                    (model, Cmd.none)

        -- don't give up if the changes feed returns an error
        OnChannelChanges channelName since (Err _) ->
            case model.channelLog of
                RemoteData.Success channelLog ->
                    if channelLog.last_seq == since && channelLog.channelName == channelName then
                        (model, delayedGetChanges 5 channelName since)
                    else
                        (model, Cmd.none)
                _ ->
                    (model, Cmd.none)

        GetPrevPage ->
            case model.channelLog of
                RemoteData.Success channel ->
                    (model, getPrevPage channel)
                _ ->
                    (model, Cmd.none)

        GetNextPage ->
            case model.channelLog of
                RemoteData.Success channel ->
                    (model, getNextPage channel)
                _ ->
                    (model, Cmd.none)

        OnChannelList (Ok channelList) ->
            ({ model | channelList = RemoteData.Success channelList }, Cmd.none)

        OnChannelList (Result.Err _) ->
            (model, Cmd.none)

        NoOp -> (model, Cmd.none)



activateRoute : AppModel -> Route -> (AppModel, Cmd Msg)
activateRoute model route =
    let
        model_ = { model | route=route }
    in
        case route of
            HomeRoute ->
                let nextModel = {model_ | channelList=RemoteData.Loading, channelLog=RemoteData.NotAsked }
                in
                    (nextModel, Http.send OnChannelList Couch.getChannelList)

            ChannelRoute channelName ->
                let nextModel = {model_ | channelLog=RemoteData.Loading }
                in
                    (nextModel, getLast100 channelName)

            ChannelDateTimeRoute channelName date ->
                let nextModel = {model_ | channelLog=RemoteData.Loading }
                in
                    (nextModel, getAt channelName date)

            NotFoundRoute ->
                let nextModel = {model_ | channelLog=RemoteData.NotAsked }
                in
                    (nextModel, Cmd.none)


init : Location -> ( AppModel, Cmd Msg )
init location =
    let route = parseLocation location
        model = initialModel route
    in
        activateRoute model route

view model =
    case model.route of
        HomeRoute ->
            Views.homePage model
        ChannelRoute channelName ->
            Views.recentChannelLog channelName model
        ChannelDateTimeRoute channelName d ->
            Views.recentChannelLog channelName model
        NotFoundRoute ->
            Views.notFoundPage

main : Program Never AppModel Msg
main =
    Navigation.program OnLocationChange {
        init = init,
        update = update,
        view = view,
        subscriptions = \_ -> Sub.none
    }
