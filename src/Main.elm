module Main exposing (..)

import Html exposing (program)
import Time
import Date


import Views
import Couch
import Models exposing (..)
import Helpers exposing (delay)


init : String -> ( Model, Cmd Msg )
init channel =
    let model = Model channel [] ""
    in
        update DoInitialView model

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
      ChannelViewResult (Ok viewResult) ->
          onChannelViewResult model viewResult

      ChannelChanges (Ok changesResult) ->
          onChannelChangesResult model changesResult

      DoInitialView ->
          (model, Couch.getLast100Messages model.channelName)

      DoChanges ->
          (model, Couch.getChanges model.channelName model.last_seq)

      ChannelViewResult (Err _) ->
          (model, delay (20 * Time.second) DoInitialView) -- backoff?

      ChannelChanges (Err _) ->
          (model, delay (5 * Time.second) DoChanges) -- backoff?

      _ ->
          (model, Cmd.none)


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
    program {
        init = init "ubuntu-mk",
        update = update,
        view = Views.displayChannelLog,
        subscriptions = \_ -> Sub.none
    }
