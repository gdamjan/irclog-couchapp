module Main exposing (..)

import Html exposing (program, Html)

import Views
import Couch
import Models exposing (..)

main : Program Never Model Msg
main =
  program {
    init = init "lugola",
    view = view,
    update = update,
    subscriptions = subscriptions
  }


init : String -> (Model, Cmd Msg)
init channel =
 ( Model channel []
 , Couch.getLast100Messages channel
 )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChannelViewResult (Ok viewResult) ->
      (
        { model | messages = viewResult.rows },
        Cmd.none
      )

    ChannelViewResult (Err _) -> -- try later?
      (model, Cmd.none)
    _ ->
      (model, Cmd.none)


view: Model -> Html Msg
view model =
  Views.displayChannelLog model


subscriptions : Model -> Sub msg
subscriptions model =
    Sub.none
