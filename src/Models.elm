module Models exposing (..)

import Date exposing (Date)
import Http exposing (Error)
import Navigation exposing (Location)
import RemoteData

type alias AppModel = { route: Route, channel: RemoteData.WebData ChannelModel,  channelList: RemoteData.WebData (List Channel) }
type alias ChannelModel = {
        channelName: String,
        messages: IrcMessages,
        last_seq: String
    }
type alias Channel = { name: String, totalMessages: Int }

initialModel : Route -> AppModel
initialModel route =
    { channel = RemoteData.NotAsked,
      channelList = RemoteData.NotAsked,
      route = route
    }

type alias IrcMessage = { timestamp: Date, sender: String, channel: String, message: String }
type alias IrcMessages = List IrcMessage

type alias ViewResult = { rows: IrcMessages, update_seq: String, total_rows: Int, offset: Int }
type alias ChangesResult = { results: IrcMessages, last_seq: String }

type Msg
    = OnChannelViewResult String (Result Http.Error ViewResult)
    | OnChannelChanges String String (Result Http.Error ChangesResult)
    | OnLocationChange Location
    | OnChannelList (Result Http.Error (List Channel))
    | DoLoadHistory

type Route
    = HomeRoute
    | ChannelRoute String
    | ChannelDateTimeRoute String Date
    | NotFoundRoute
