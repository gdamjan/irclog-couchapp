module Views exposing (..)

import Html.Events exposing (onClick)
import Html.Attributes exposing (style, href, id, colspan, align)
import Html exposing (..)
import Date
import RemoteData

import Models exposing (..)
import Helpers exposing (groupWith)


homePage model =
    div [] [text "Hello World!"]

notFoundPage =
    div [] [text "Not Found"]

channelLogAt channelName d =
    div [] [text (toString d)]

recentChannelLog : String -> AppModel -> Html Msg
recentChannelLog channelName model =
    div [] [
        pageHeader ("irc logs for #" ++ channelName),
        historyButton DoLoadHistory,
        maybeLoading model,
        pageFooter
    ]

maybeLoading : AppModel -> Html Msg
maybeLoading model =
    case model.channel of
        RemoteData.Loading ->
            text "Loading…"
        RemoteData.Success channel ->
            ircLogTable channel.messages
        RemoteData.Failure _ ->
            text "Failure"
        RemoteData.NotAsked ->
            text "-¿then why are we here?-"


ircLogTable : IrcMessages -> Html msg
ircLogTable messages =
    -- FIXME: groupBy and tbody
    Html.table [style [("width","100%")]] (
        groupWith dateOfMessage messages
        |> List.map (\(group, values) -> tableGroup group values)
    )

dateOfMessage : {a | timestamp: Date.Date } -> String
dateOfMessage m =
    String.join "-"
    <| [ Date.year m.timestamp |> toString,
         Date.month m.timestamp |> toString |> String.padLeft 2 '0',
         Date.day m.timestamp |> toString |> String.padLeft 2 '0'
    ]


tableGroup group values =
    let css = [("color", "#a0a0a0"),
               ("border-top", "1px dashed #a0a0a0")
        ]
        groupHeading = th [style css, colspan 2, align "right"]
            <| [a [] [text group]]
    in
        tbody []
            <| tr [] [ groupHeading ] :: List.map tableRow values


tableRow row =
    let cell1 = td [style [("vertical-align", "baseline")]] [nickname row.sender, messageText row.message]
        cell2 = td [style [("vertical-align", "top")]] [messageTime row.timestamp row.channel]
    in
        tr [] [cell1, cell2]

nickname sender =
    let css = [
            ("font-size", "70%"),
            ("padding", "1px 2px"),
            ("background-color", "black"), -- FIXME: random/hashed pastel color
            ("color", "white"),
            ("margin", "0 6px 0 2px")
        ]
    in
        span [style css] [text sender]

messageText message =
    span [] [text message] -- FIXME: autolink, simple markdown (bold, italic, monospace), emojis

messageTime timestamp channel =
    let css = [
            ("font-size", "80%"),
            ("font-family", "monospace"),
            ("text-decoration", "none"),
            ("color", "#808080")
        ]
        timeString = String.join ":" [
            Date.hour timestamp |> toString |> String.padLeft 2 '0',
            Date.minute timestamp |> toString |> String.padLeft 2 '0',
            Date.second timestamp |> toString |> String.padLeft 2 '0'
        ]
        iso8601 = "FIXME-xyz"
        link = "#/" ++ channel ++ "/" ++ iso8601
    in
        a [style css, href link, id iso8601] [text timeString]

historyButton msg =
    div [style [("text-align", "center")]] [button [ onClick msg ] [ text "load some history" ]]

pageHeader title =
    let css = [
            ("text-shadow", "1px 1px 4px rgba(0, 0, 0, 0.3)"),
            ("color", "#444444"),
            ("padding", "6px")
        ]
    in
        Html.header [style css] [
            h1 [] [text title]
        ]

pageFooter =
    let footerCss = [
            ("border-top", "1px dashed #aaaaaa"),
            ("margin-top", "1.5em"),
            ("padding", "8px 6px 0.5em 6px"),
            ("background-color", "#eeeeee")
        ]
        linkCss = [
            ("text-decoration", "none"),
            ("color", "#555555")
        ]
    in
        Html.footer [style footerCss, id "footer"] [
            a [href "https://irc.softver.org.mk/", style linkCss] [text "irclog home page"]
        ]
