module Main exposing (..)

import Navigation exposing (program, Location)
import Time
import Date
import Http

import Views
import Couch
import Models exposing (..)
import Routing exposing (parseLocation)
import Helpers exposing (delay)


init : Location -> ( Model, Cmd Msg )
init location =
    let initialModel = { route=HomeRoute, messages=[], channelName="", last_seq="" } -- this is bad, perhaps move to Maybe/Nothing
    in
        onLocationChange initialModel location


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        OnLocationChange location ->
            onLocationChange model location

        OnChannelViewResult (Ok viewResult) ->
            onChannelViewResult model viewResult

        OnChannelChanges (Ok changesResult) ->
            onChannelChangesResult model changesResult

        DoInitialView ->
            (model, Http.send OnChannelViewResult (Couch.getLast100Messages model.channelName))

        DoChanges ->
            (model, Http.send OnChannelChanges (Couch.getChanges model.channelName model.last_seq))

        OnChannelViewResult (Err _) ->
            (model, delay (20 * Time.second) DoInitialView) -- backoff?

        OnChannelChanges (Err _) ->
            (model, delay (5 * Time.second) DoChanges) -- backoff?

        _ ->
            (model, Cmd.none)


onLocationChange : Model -> Location -> (Model, Cmd Msg)
onLocationChange model location =
    -- FIXME: how do I stop the ongoing longpoll request - also need to ignore any changes results if they come by in the mean time
    let
        newRoute = parseLocation location
        newmodel = { model | route = newRoute }
    in
        case newRoute of
            HomeRoute ->
                (newmodel, Cmd.none)
            ChannelRoute channel ->
                update DoInitialView {newmodel | channelName = channel}
            ChannelDateTimeRoute _ _->
                (newmodel, Cmd.none)
            NotFoundRoute ->
                (newmodel, Cmd.none)


onChannelViewResult : Model -> ViewResult -> (Model, Cmd Msg)
onChannelViewResult model viewResult =
    let messages = List.reverse viewResult.rows
        last_seq = viewResult.update_seq
        newmodel = {model | messages = messages, last_seq = last_seq}
    in
        update DoChanges newmodel


onChannelChangesResult : Model -> ChangesResult -> (Model, Cmd Msg)
onChannelChangesResult model changesResult =
    let results = List.sortBy (\doc -> Date.toTime doc.timestamp) changesResult.results
        messages = List.append model.messages results
        last_seq = changesResult.last_seq
        newmodel = { model | messages = messages, last_seq = last_seq }
    in
        update DoChanges newmodel


main : Program Never Model Msg
main =
    Navigation.program OnLocationChange {
        init = init,
        update = update,
        view = Views.mainView,
        subscriptions = \_ -> Sub.none
    }
