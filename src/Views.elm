module Views exposing (..)

import Html.Events exposing (onClick)
import Html.Attributes exposing (style, href, id, class, colspan, align, title)
import Html exposing (..)
import Html.Keyed
import RemoteData

import Models exposing (..)
import Helpers exposing (..)
import Message


maybeLoading : RemoteData.RemoteData e a -> (a -> Html Msg) -> Html Msg
maybeLoading remoteData f =
    case remoteData of
        RemoteData.Loading ->
            pageLoader
        RemoteData.Success data ->
            f data
        RemoteData.Failure _ ->
            text "Failure"
        RemoteData.NotAsked ->
            text "-¿then why are we here?-"

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
        paginationButton "back" GetPrevPage,
        maybeLoading model.channelLog ircLogTable,
        case model.route of
            ChannelDateTimeRoute _ _ -> paginationButton "forward" GetNextPage
            _ -> waitingForUpdates,
        pageFooter
    ]


ircLogTable : ChannelLog -> Html msg
ircLogTable channel =
    Html.table [] (
        channel.messages
        --|> List.sortBy (\m -> m.timestamp)
        |> groupWith (\m -> dateOf m.timestamp)
        |> List.map (\(group, values) -> tableGroup channel.channelName group values)
    )

tableGroup channelName group values =
    let
        link = "#/" ++ channelName ++ "/" ++ group ++ "T00:00:00"
        groupHeading = th [colspan 2, align "right"]
            <| [a [href link, id group] [text group]]
        key = link
    in
        Html.Keyed.node "tbody" []
            <| (key, tr [] [ groupHeading ]) :: List.map tableRow values


tableRow row =
    let cell1 = td [] <| Message.toHtml row
        cell2 = td [class "timestamp"] [messageTime row.timestamp row.channel row.id]
        key = row.id
    in
        (key, tr [] [cell1, cell2])

messageTime timestamp channel msgId =
    let css = [
            ("font-size", "80%"),
            ("font-family", "monospace"),
            ("text-decoration", "none"),
            ("color", "#808080")
        ]
        iso8601 = datetimeOf timestamp
        link = "#/" ++ channel ++ "/" ++ msgId
    in
        a [style css, href link, id msgId] [text (timeOf timestamp)]

paginationButton txt msg =
    div [style [("text-align", "center")]] [button [ onClick msg ] [ text txt]]

waitingForUpdates =
    let css = [
            ("text-align","center"),
            ("font-size", "60%"),
            ("opacity","0.5")
        ]
    in
        div [style css] [text "…waiting for updates…"]

pageHeader title =
    Html.header [id "header"] [
        h1 [] [text title]
    ]

pageFooter =
    Html.footer [id "footer"] [
        a [href "https://irc.softver.org.mk/"] [text "irclog home page"]
    ]

pageLoader =
    div [id "page-loader"]
        (List.repeat 4 (span [] []))

notFoundPage =
    div [] [text "Not Found"]
