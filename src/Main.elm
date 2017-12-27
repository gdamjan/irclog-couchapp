module Main exposing (..)

import Html exposing (program, Html)
import Task
import Time
import Date

import Views
import Couch
import Models exposing (..)
import Helpers exposing (delay)


main : Program Never Model Msg
main =
    program {
        init = init "lugola",
        update = update,
        view = Views.displayChannelLog,
        subscriptions = \_ -> Sub.none
    }


init : String -> (Model, Cmd Msg)
init channel =
    ( Model channel [] "",
      Task.perform identity (Task.succeed DoInitialView)
    )

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

onChannelViewResult model viewResult =
    let messages = List.reverse viewResult.rows
        last_seq = viewResult.update_seq
    in
      (
        { model | messages = messages, last_seq = last_seq },
        Task.perform identity (Task.succeed DoChanges)
      )

onChannelChangesResult model changesResult =
    let results = List.sortBy (\doc -> Date.toTime doc.timestamp) changesResult.results
        messages = List.append model.messages results
        last_seq = changesResult.last_seq
    in
      (
        { model | messages = messages, last_seq = last_seq },
        Task.perform identity (Task.succeed DoChanges)
      )
