module Models exposing (..)

import Date exposing (Date)
import Http exposing (Error)
import Navigation exposing (Location)

type alias AppModel = { route: Route, channel: Maybe ChannelModel }
type alias ChannelModel = { channelName: String, messages: IrcMessages }

type alias IrcMessage = { timestamp: Date, sender: String, channel: String, message: String }
type alias IrcMessages = List IrcMessage

type alias ViewResult = { rows: IrcMessages, update_seq: String, total_rows: Int, offset: Int }
type alias ChangesResult = { results: IrcMessages, last_seq: String }

type Msg =
  OnChannelViewResult String (Result Http.Error ViewResult)
  | OnChannelChanges String (Result Http.Error ChangesResult)
  | OnLocationChange Location
  | DoChanges String String
  | DoLoadHistory

type Route
    = HomeRoute
    | ChannelRoute String
    | ChannelDateTimeRoute String Date
    | NotFoundRoute
