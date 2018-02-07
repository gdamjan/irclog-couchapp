module Main exposing (..)

import Navigation exposing (program, Location)
import Http
import RemoteData

import Views
import Couch
import Channel
import Models exposing (..)
import Routing exposing (parseLocation)

update : Msg -> AppModel -> (AppModel, Cmd Msg)
update msg model =
    case msg of
        OnLocationChange location ->
            let route = parseLocation location
            in
                activateRoute model route

        OnChannelViewResult channelName (Ok viewResult) ->
            Channel.channelViewResult channelName viewResult model

        OnChannelViewResult _ (Err _) -> (model, Cmd.none)

        OnNextPageResult channelName last (Ok viewResult) ->
            Channel.nextPage channelName last viewResult model

        OnPrevPageResult channelName head (Ok viewResult) ->
            Channel.prevPage channelName head viewResult model

        OnPrevPageResult _ _ (Err _) -> (model, Cmd.none)
        OnNextPageResult _ _ (Err _) -> (model, Cmd.none)

        OnChannelChanges channelName since (Ok changesResult) ->
            Channel.updateChanges channelName since changesResult model

        -- don't give up if the changes feed returns an error
        OnChannelChanges channelName since (Err err) ->
            Channel.errorChanges channelName since err model

        GetPrevPage ->
            case model.channelLog of
                RemoteData.Success channel ->
                    (model, Channel.getPrevPage channel)
                _ ->
                    (model, Cmd.none)

        GetNextPage ->
            case model.channelLog of
                RemoteData.Success channel ->
                    (model, Channel.getNextPage channel)
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
                    (nextModel, Channel.getLast100 channelName)

            ChannelDateTimeRoute channelName date ->
                let nextModel = {model_ | channelLog=RemoteData.Loading }
                in
                    (nextModel, Channel.getAt channelName date)

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
