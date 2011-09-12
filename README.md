# IrcLog CouchApp

This is a CouchApp to view irc logs stored in a CouchDB database. The irclogs can be stored by my https://github.com/gdamjan/erlang-irc-bot program, or anything else that will store them in the following structure:


    {
      "sender": "SomeOne",
      "channel": "trollclub",
      "message": "hi hey, can I ask a question",
      "timestamp": 1283207105.891249
    }


## Install

    couchapp push . http://localhost:5984/irclog

## Use

Visit the canonical URL:

    http://localhost:5984/irclog/_design/log/_rewrite

but probably it's better if you setup a vhost.

## Setup vhosts

Go to the configuration page of CouchDB (it's right there on the right in Futon), and then click on "Add a new section", set `vhosts` as section, your domain name as option, and `/irclog/_design/log/_rewrite` as value. This thing in the config file will look like:

    [vhosts]
    irclog.example.tld = /irclog/_design/log/_rewrite

or with `curl`:

    curl -X PUT http://localhost:5984/_config/vhosts/irclog.example.tld \
        -d '"/irclog/_design/log/_rewrite"'


Read the documentation about [CouchDB Virtual Hosts](http://wiki.apache.org/couchdb/Virtual_Hosts) for
further info.


## Todo

* archive browser - calendar, dates
* full-text search
* tag cloud
* compact lines, if same sender AND timestamp diff < 10 secs AND number of words < 2
* algorithmic persistent nick colorizer
* histogram of activity

## License

Apache 2.0
