# IrcLog CouchApp - a web app to view irclogs

The logs are stored in couchdb.

The single page web app is written in elm and storred as a
[couchapp](http://couchapp.readthedocs.io/en/latest/intro/what-is-couchapp.html)
in couchdb attachments.


# Quick start - for developers

Clone this repo, run `elm-reactor` and open [http://localhost:8000/dev.html]. elm-reactor
will compile the source automatically when needed (will also download dependencies).
Then just edit files and hit refresh.


# Production…

To compile run `make build` that will build everything in `dist/`,
which you can then copy to a web server (or just serve with `python -m http.server`).
`uglifyjs` is required for this too.

Finally run `make publish` to push a specially prepared design document to a couchdb instance. (TODO which one)


# Requirements

* [elm build tools](https://guide.elm-lang.org/install.html)
* [couchapp](http://couchapp.readthedocs.io/en/latest/couchapp/install.html) to push files as a design document in couchdb
