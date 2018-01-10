module Models exposing (..)

import Date exposing (Date)
import Http exposing (Error)
import Navigation exposing (Location)
import RemoteData

type alias AppModel = {
        route: Route,
        channelLog: RemoteData.WebData ChannelLog,
        channelList: RemoteData.WebData (List Channel)
    }

type alias ChannelLog = {
        channelName: String,
        messages: IrcMessages,
        last_seq: String
    }

type alias Channel = { name: String, totalMessages: Int }

initialModel : Route -> AppModel
initialModel route =
    { channelLog = RemoteData.NotAsked,
      channelList = RemoteData.NotAsked,
      route = route
    }

type alias IrcMessage = { id: String, timestamp: Date, sender: String, channel: String, message: String }
type alias IrcMessages = List IrcMessage

type alias ViewResult = { rows: IrcMessages, last_seq: String, total_rows: Int, offset: Int }
type alias ChangesResult = { rows: IrcMessages, last_seq: String }

type Msg
    = OnChannelViewResult String (Result Http.Error ViewResult)
    | OnPrevPageResult String IrcMessage (Result Http.Error ViewResult)
    | OnNextPageResult String IrcMessage (Result Http.Error ViewResult)
    | OnChannelChanges String String (Result Http.Error ChangesResult)
    | OnLocationChange Location
    | OnChannelList (Result Http.Error (List Channel))
    | GetPrevPage | GetNextPage
    | NoOp

type Route
    = HomeRoute
    | ChannelRoute String
    | ChannelDateTimeRoute String Date
    | NotFoundRoute
