module Main exposing (..)

import Html.Events exposing (onClick)
import Html.Attributes exposing (..)
import Html exposing (..)

import Couch
import Models exposing (..)


main =
  Html.program {
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
  div [(class "main")] [
    header [] [text ("irc logs for #" ++ model.channelName)],
    button [ onClick Decrement ] [ text "-" ],
    irctable [] (List.reverse model.messages),
    button [ onClick Increment ] [ text "+" ]
  ]


irctable: List (Html.Attribute Msg) -> IrcMessages -> Html Msg
irctable attrs messages =
  Html.table attrs (List.map singlerow messages)

singlerow : IrcMessage -> Html Msg
singlerow message =
  tr [] [
    td [] [text message.sender],
    td [] [text message.message],
    td [] [text (toString message.timestamp)]
  ]

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none