# IrcLog CouchApp - a web app to view irclogs

The logs are stored in couchdb.

The single page web app uses elm and couchdb


# Quick start

```
elm-reactor
```
and open http://localhost:8000/dev.html - elm-reactor will compile the source automatically when needed.


# Production…

To compile:
```
elm-make src/Main.elm --output dist/elm.compiled.js
```

FIXME: add command to pack the full couchapp and upload to CouchDB
