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


init : Location -> ( AppModel, Cmd Msg )
init location =
    let initialModel = AppModel HomeRoute Nothing
    in
        onLocationChange initialModel location


update : Msg -> AppModel -> (AppModel, Cmd Msg)
update msg model =
    case msg of
        OnLocationChange location ->
            onLocationChange model location

        OnChannelViewResult channelName (Ok viewResult) ->
            let (chan, last_seq) = createChannel channelName viewResult
                newmodel = { model | channel=Just chan }
            in
                update (DoChanges channelName last_seq) newmodel

        OnChannelChanges channelName (Ok changesResult) ->
            case model.channel of
                Nothing ->
                    (model, Cmd.none)
                Just chan ->
                    let
                        (chan_, last_seq) = updateChannel chan changesResult
                        newmodel = { model | channel=Just chan_ }
                    in
                        update (DoChanges channelName last_seq) newmodel

        DoChanges channelName last_seq ->
            (model, Http.send (OnChannelChanges channelName) (Couch.getChanges channelName last_seq))

        OnChannelViewResult _ (Err _) ->
            (model, Cmd.none) -- delay (20 * Time.second) DoInitialView) -- backoff?

        OnChannelChanges _ (Err _) ->
            (model, Cmd.none) -- delay (5 * Time.second) DoChanges) -- backoff?

        DoLoadHistory ->
            (model, Cmd.none)



onLocationChange : AppModel -> Location -> (AppModel, Cmd Msg)
onLocationChange model location =
    -- FIXME: how do I stop the ongoing longpoll request - also need to ignore any changes results if they come by in the mean time
    let
        newRoute = parseLocation location
        newmodel = AppModel newRoute Nothing
    in
        case newRoute of
            HomeRoute ->
                (newmodel, Cmd.none)

            ChannelRoute channelName ->
                (newmodel, Http.send (OnChannelViewResult channelName) (Couch.getLast100Messages channelName))

            ChannelDateTimeRoute _ _->
                (newmodel, Cmd.none)

            NotFoundRoute ->
                (newmodel, Cmd.none)


createChannel : String -> ViewResult -> (ChannelModel, String)
createChannel channelName viewResult =
    let messages = List.reverse viewResult.rows
        last_seq = viewResult.update_seq
    in
        (ChannelModel channelName messages, last_seq)

updateChannel : ChannelModel -> ChangesResult -> (ChannelModel, String)
updateChannel chan changesResult =
    let results = List.sortBy (\doc -> Date.toTime doc.timestamp) changesResult.results
        messages = List.append chan.messages results
        last_seq = changesResult.last_seq
    in
        ({ chan | messages = messages }, last_seq)


main : Program Never AppModel Msg
main =
    Navigation.program OnLocationChange {
        init = init,
        update = update,
        view = Views.mainView,
        subscriptions = \_ -> Sub.none
    }
