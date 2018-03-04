module Message exposing (toHtml)

import Html
import Html.Attributes
import Regex
import Identicon
import Color.Convert


{-
TODO:
- action message (^\001ACTION xyz\001$)
- url in message (handle trailing parens, quotes etc)
- monospace/code between ` `
- bold between * *
- italic between _ _
-}

toHtml : { a | message : String, sender : String } -> List (Html.Html msg)
toHtml row =
    nickname row.sender :: spacer :: linkify row.message


nickname : String -> Html.Html msg
nickname sender =
    let css = [
            ("font-size", "70%"),
            ("padding", "1px 2px"),
            ("background-color", colorize sender),
            ("color", "black")
        ]
    in
        Html.span [Html.Attributes.style css] [Html.text sender]

spacer =
    Html.text "\x00A0"

colorize : String -> String
colorize s =
    Identicon.defaultColor s
    |> Color.Convert.colorToCssRgb

linkify : String -> List (Html.Html msg)
linkify s =
    recurseLinkify matcher s []

urlRegex : Regex.Regex
urlRegex =
    Regex.regex """\\b((?:(?:([a-z][\\w\\.-]+:/{1,3})|www|ftp\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|\\}\\]|[^\\s`!()\\[\\]{};:'\".,<>?%1%2%3%4%5%6])|[a-z0-9.\\-+_]+@[a-z0-9.\\-]+[.][a-z]{1,5}[^\\s/`!()\\[\\]{};:'\".,<>?]))"""

matcher : String -> List Regex.Match
matcher =
    Regex.find (Regex.AtMost 1) urlRegex

recurseLinkify : (String -> List Regex.Match) -> String -> List (Html.Html msg) -> List (Html.Html msg)
recurseLinkify matcher string acc =
    case matcher string of
        match::_ ->
            let
                pre = String.left match.index string
                url = match.match
                matchEnd = match.index + (String.length url)
                rest = String.dropLeft matchEnd string
                acc_ = acc ++ [Html.text pre, makeurl url]
            in
                recurseLinkify matcher rest acc_
        [] ->
            acc ++ [Html.text string]

shorten s =
    if String.length s > 50 then
        [Html.text (String.left 50 s), Html.text "…"]
    else
        [Html.text s]

makeurl s =
    if String.startsWith "https://" s || String.startsWith "http://" s then
        Html.a [Html.Attributes.href s] (shorten s)
    else
        Html.a [Html.Attributes.href ("http://"++s)] (shorten s)
