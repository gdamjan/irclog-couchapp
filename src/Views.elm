module Views exposing (..)

import Html.Events exposing (onClick)
import Html.Attributes exposing (style, href, id, class, colspan, align, title)
import Html exposing (..)
import RemoteData

import Models exposing (..)
import Helpers exposing (..)


maybeLoading : RemoteData.RemoteData e a -> (a -> Html Msg) -> Html Msg
maybeLoading remoteData f =
    case remoteData of
        RemoteData.Loading ->
            loadingAnimation
        RemoteData.Success data ->
            f data
        RemoteData.Failure _ ->
            text "Failure"
        RemoteData.NotAsked ->
            text "-¿then why are we here?-"

loadingAnimation =
    div [ class "container" ]
        [ div [class "item item-1"] []
        , div [class "item item-2"] []
        , div [class "item item-3"] []
        , div [class "item item-4"] []
        ]

notFoundPage =
    div [] [text "Not Found"]

channelLogAt channelName d =
    div [] [text (toString d), pageFooter]

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
        maybeLoading model.channelLog ircLogTable,
        pageFooter
    ]


ircLogTable : ChannelLog -> Html msg
ircLogTable channel =
    Html.table [] (
        groupWith (\m -> dateOf m.timestamp) channel.messages
        |> List.map (\(group, values) -> tableGroup channel.channelName group values)
    )

tableGroup channelName group values =
    let
        link = "#/" ++ channelName ++ "/" ++ group
        groupHeading = th [colspan 2, align "right"]
            <| [a [href link, id group] [text group]]
    in
        tbody []
            <| tr [] [ groupHeading ] :: List.map tableRow values


tableRow row =
    let cell1 = td [] [nickname row.sender, text "\x00A0", messageText row.message]
        cell2 = td [class "timestamp"] [messageTime row.timestamp row.channel]
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
    Html.header [id "header"] [
        h1 [] [text title]
    ]

pageFooter =
    Html.footer [id "footer"] [
        a [href "https://irc.softver.org.mk/"] [text "irclog home page"]
    ]
