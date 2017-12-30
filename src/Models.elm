module Models exposing (..)

import Date exposing (Date)
import Http exposing (Error)

type alias Model = { channelName: String, messages: IrcMessages, last_seq: String }

type EventData =
    TopicChange String
    | Message String

type alias IrcMessage = { timestamp: Date, sender: String, channel: String, event: EventData }
type alias IrcMessages = List IrcMessage

type alias ViewResult = { rows: IrcMessages, update_seq: String, total_rows: Int, offset: Int }
type alias ChangesResult = { results: IrcMessages, last_seq: String }

type Msg =
  OnChannelViewResult (Result Http.Error ViewResult)
  | OnChannelChanges (Result Http.Error ChangesResult)
  | DoChanges
  | DoInitialView
  | DoLoadHistory
