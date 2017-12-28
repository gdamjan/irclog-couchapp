module Views exposing (..)

import Html.Events exposing (onClick)
import Html.Attributes exposing (style, href, id)
import Html exposing (..)
import Date

import Models exposing (..)

displayChannelLog : Model -> Html Msg
displayChannelLog model =
    div [] [
        header model.channelName,
        historyButton LoadHistory,
        ircLogTable model.messages,
        footer
    ]

ircLogTable: IrcMessages -> Html msg
ircLogTable messages =
    Html.table [style [("width","100%")]] (List.map singlerow messages) -- FIXME: groupBy and tbody

singlerow : IrcMessage -> Html msg
singlerow row =
    tr [] [
        td [style [("vertical-align", "baseline")]] [nickname row.sender, ircMessage row.message],
        td [style [("vertical-align", "top")]] [timestamp row]
    ]

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

ircMessage message =
    span [] [text message] -- FIXME: autolink, simple markdown (bold, italic, monospace), emojis

timestamp row =
    let css = [
            ("font-size", "80%"),
            ("font-family", "monospace"),
            ("text-decoration", "none"),
            ("color", "#808080")
        ]
        timeString = String.join ":" [
            (Date.hour row.timestamp |> toString |> String.padLeft 2 '0'),
            (Date.minute row.timestamp |> toString |> String.padLeft 2 '0'),
            (Date.second row.timestamp |> toString |> String.padLeft 2 '0')
        ]
        iso8601 = "FIXME-xyz"
        link = "#/" ++ row.channel ++ "/" ++ iso8601
    in
        a [style css, href link, id iso8601] [text timeString]

historyButton msg =
    div [style [("text-align", "center")]] [button [ onClick msg ] [ text "load some history" ]]

header channel =
    let css = [
            ("text-shadow", "1px 1px 4px rgba(0, 0, 0, 0.3)"),
            ("color", "#444444"),
            ("padding", "6px")
        ]
    in
        Html.header [style css] [
            h1 [] [text ("irc logs for #" ++ channel)]
        ]

footer =
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
