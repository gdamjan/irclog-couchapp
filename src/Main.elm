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

createChannel channelName viewResult =
    let messages = List.reverse viewResult.rows
        last_seq = viewResult.update_seq
    in
        { channelName=channelName, messages=messages, last_seq=last_seq }

updateChannel channel changesResult =
    let results = List.sortBy (\doc -> Date.toTime doc.timestamp) changesResult.results
        messages = List.append channel.messages results
        last_seq = changesResult.last_seq
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
                last_seq = viewResult.update_seq
                newModel = { model | channel=RemoteData.Success chan }
            in
                (newModel, getChanges channelName last_seq)

        OnChannelChanges channelName since (Ok changesResult) ->
        -- only update the model if, the request was made for the same channel name and last_seq in the model hasn't changed meanwhile
            case model.channel of
                RemoteData.Success channel ->
                    if channel.last_seq == since && channel.channelName == channelName then
                    let
                        chan = updateChannel channel changesResult
                        newmodel = { model | channel= RemoteData.Success chan }
                        last_seq = changesResult.last_seq
                    in
                        (newmodel, getChanges channelName last_seq)
                    else
                        (model, Cmd.none)
                _ ->
                    (model, Cmd.none)

        OnChannelViewResult _ (Err _) ->
            (model, Cmd.none) -- delay (20 * Time.second) DoInitialView) -- backoff?

        OnChannelChanges channelName since (Err _) ->
            case model.channel of
                RemoteData.Success channel ->
                    if channel.last_seq == since && channel.channelName == channelName then
                        (model, delayedGetChanges 5 channelName since)
                    else
                        (model, Cmd.none)
                _ ->
                    (model, Cmd.none)

        DoLoadHistory ->
            (model, Cmd.none)


activateRoute : AppModel -> Route -> (AppModel, Cmd Msg)
activateRoute model route =
    let
        model_ = { model | route=route }
    in
        case route of
            HomeRoute ->
                let model = {model_ | channel=RemoteData.NotAsked }
                in
                    (model, Cmd.none)

            ChannelRoute channelName ->
                let model = {model_ | channel=RemoteData.Loading }
                in
                    (model, getLast100 channelName)

            ChannelDateTimeRoute _ _->
                let model = {model_ | channel=RemoteData.Loading }
                in
                    (model, Cmd.none)

            NotFoundRoute ->
                let model = {model_ | channel=RemoteData.NotAsked }
                in
                    (model, Cmd.none)


init : Location -> ( AppModel, Cmd Msg )
init location =
    let route = parseLocation location
        model = initialModel route
    in
        activateRoute model route
--        (model, Task.perform identity (Task.succeed (OnLocationChange location)))

view model =
    case model.route of
        HomeRoute ->
            Views.homePage model
        ChannelRoute channelName ->
            Views.recentChannelLog channelName model
        ChannelDateTimeRoute channelName d ->
            Views.channelLogAt channelName d
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
