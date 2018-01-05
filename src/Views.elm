module Views exposing (..)

import Html.Events exposing (onClick)
import Html.Attributes exposing (style, href, id, colspan, align, title)
import Html exposing (..)
import RemoteData

import Models exposing (..)
import Helpers exposing (..)


maybeLoading : RemoteData.RemoteData e a -> (a -> Html Msg) -> Html Msg
maybeLoading remoteData f =
    case remoteData of
        RemoteData.Loading ->
            text "Loading…"
        RemoteData.Success data ->
            f data
        RemoteData.Failure _ ->
            text "Failure"
        RemoteData.NotAsked ->
            text "-¿then why are we here?-"


notFoundPage =
    div [] [text "Not Found"]

channelLogAt channelName d =
    div [] [text (toString d)]

homePage model =
    let css = [("padding", "6px")]
    in
        div [] [
            pageHeader "IRC logs with realtime updates",
            div [style css] [text "This web page is a viewer of irclogs collected by my ",
                a [href "https://github.com/gdamjan/erlang-irc-bot"] [text "erlang irc bot"],
                text ". The bot stores the logs in a CouchDB where this web-app (or couchapp) is also stored. You can also ",
                a [href "http://wiki.apache.org/couchdb/Replication"] [text "replicate"], text " the database at https://irc.softver.org.mk/api freely."],
            maybeLoading model.channelList channelList,
            div [style css] [text "If you want your irc channel on freenode logged, contact 'damjan' on #lugola."],
            pageFooter
        ]

channelList list =
    let css = [
            ("list-style-type", "square"),
            ("padding-left", "2em"),
            ("margin", "1em 0")
        ]
    in
        div [style [("padding", "6px")]] [
            text "The following channels are currently logged:",
            ul [style css] <| List.map channelItem list
        ]

channelItem c =
    li [] [
        a [href ("#/"++c.name), title ("total messages: "++toString c.totalMessages)] [text c.name]
    ]

recentChannelLog : String -> AppModel -> Html Msg
recentChannelLog channelName model =
    div [] [
        pageHeader ("irc logs for #" ++ channelName),
        historyButton DoLoadHistory,
        maybeLoading model.channel ircLogTable,
        pageFooter
    ]


ircLogTable : ChannelModel -> Html msg
ircLogTable channel =
    let css = [
        ("width","100%"),
        ("padding", "0.2em")
    ]
    in
        Html.table [style css] (
            groupWith (\m -> dateOf m.timestamp) channel.messages
            |> List.map (\(group, values) -> tableGroup channel.channelName group values)
        )

tableGroup channelName group values =
    let css = [
            ("color", "#a0a0a0"),
            ("border-top", "1px dashed #a0a0a0")
        ]
        link = "#/" ++ channelName ++ "/" ++ group
        linkCss = [
            --("text-decoration", "none"),
            ("color", "#808080")
        ]
        groupHeading = th [style css, colspan 2, align "right"]
            <| [a [style linkCss, href link, id group] [text group]]
    in
        tbody []
            <| tr [] [ groupHeading ] :: List.map tableRow values


tableRow row =
    let cell1 = td [style [("vertical-align", "baseline")]] [nickname row.sender, text "\x00A0", messageText row.message]
        cell2 = td [style [("vertical-align", "top")]] [messageTime row.timestamp row.channel]
    in
        tr [] [cell1, cell2]

nickname sender =
    let css = [
            ("font-size", "70%"),
            ("padding", "1px 2px"),
            ("background-color", colorize sender),
            ("color", "black")
        ]
    in
        span [style css] [text sender]

messageText message =
    text message -- FIXME: autolink, simple markdown (bold, italic, monospace), emojis

messageTime timestamp channel =
    let css = [
            ("font-size", "80%"),
            ("font-family", "monospace"),
            ("text-decoration", "none"),
            ("color", "#808080")
        ]
        iso8601 = datetimeOf timestamp
        link = "#/" ++ channel ++ "/" ++ iso8601
    in
        a [style css, href link, id iso8601] [text (timeOf timestamp)]

historyButton msg =
    div [style [("text-align", "center")]] [button [ onClick msg ] [ text "load some history" ]]

pageHeader title =
    let css = [
            ("text-shadow", "1px 1px 4px rgba(0, 0, 0, 0.3)"),
            ("color", "#444444"),
            ("padding", "6px"),
            ("margin", "1em 0")
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
