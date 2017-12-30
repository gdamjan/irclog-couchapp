module Routing exposing (..)

import Navigation exposing (Location)
import Models exposing (Route(..))
import UrlParser exposing (..)
import Date


datetime : Parser (Date.Date -> b) b
datetime =
    custom "DATETIME" (\str ->
        case Date.fromString str of
            (Ok d) -> (Ok d)
            (Err _) ->
                String.toFloat str
                |> Result.map ((*) 1000)
                |> Result.map Date.fromTime
    )

matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map HomeRoute top,
          map ChannelRoute (top </> string),
          map ChannelDateTimeRoute (top </> string </> datetime )
        --  map SettingsRoute "settings"
        --  map SearchRoute "search"
        ]


parseLocation : Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute
