# IrcLog CouchApp

This is a CouchApp to view irc logs stored in a CouchDB database. The irclogs
can be stored by my https://github.com/gdamjan/erlang-irc-bot program, or
anything else that will store them in the following structure:


    {
      "sender": "SomeOne",
      "channel": "trollclub",
      "message": "hi hey, can I ask a question",
      "timestamp": 1283207105.891249
    }


## Install

    couchapp push . http://localhost:5984/irclog


## Todo

* archive browser - calendar, dates
* full-text search
* tag cloud
* compact lines, if same sender AND timestamp diff < 10 secs AND number of words < 2
* algorithmic persistent nick colorizer
* histogram of activity

## License

Apache 2.0
