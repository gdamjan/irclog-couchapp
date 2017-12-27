module Main exposing (..)

import Html exposing (program, Html)
import Process
import Task
import Time
import Date

import Views
import Couch
import Models exposing (..)

main : Program Never Model Msg
main =
  program {
    init = init "lugola",
    view = view,
    update = update,
    subscriptions = \_ -> Sub.none
  }


init : String -> (Model, Cmd Msg)
init channel =
 ( Model channel [] ""
 , Couch.getLast100Messages channel
 )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChannelViewResult (Ok viewResult) ->
      (
        { model
        | messages = List.reverse viewResult.rows
        , last_seq = viewResult.update_seq
        } -- Task.perform identity (Task.succeed DoChanges) ??
        , Couch.getChanges model.channelName viewResult.update_seq
      )

    ChannelChanges (Ok changesResult) ->
        let results = List.sortBy (\doc -> Date.toTime doc.timestamp) changesResult.results
        in
            (
              { model
              | messages = List.append model.messages results
              , last_seq = changesResult.last_seq
              } -- Task.perform identity (Task.succeed DoChanges) ??
              , Couch.getChanges model.channelName changesResult.last_seq
            )

    DoChanges ->
      (model, Couch.getChanges model.channelName model.last_seq)

    ChannelViewResult (Err _) -> -- try later?
      (model, Cmd.none)

    ChannelChanges (Err _) -> -- repeat after a while
      (model, delay (5 * Time.second) DoChanges)

    _ ->
      (model, Cmd.none)


view: Model -> Html Msg
view model =
  Views.displayChannelLog model


delay : Time.Time -> msg -> Cmd msg
delay time msg =
  Process.sleep time
  |> Task.perform (\_ -> msg)
