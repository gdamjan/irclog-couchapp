DIST = ./dist

ELM_ENTRYPOINT = ./src/Main.elm
MAIN_JS = main.js
MAIN_MIN_JS = main.min.js

# my servers - use your own
SERVER = damjan.softver.org.mk:public_html/elm-wip/
COUCHDB = https://db.softver.org.mk/irclog


ELM_FILES = $(shell find src/ -type f -name '*.elm')
CSS_FILES = $(shell find css/ -type f -name '*.css')
IMG_FILES = $(shell find img/ -type f -name '*.png')

CSS_DIST = $(addprefix $(DIST)/,$(CSS_FILES))
CSS_DIST_GZ = $(addsuffix .gz,$(CSS_DIST))
IMG_DIST = $(addprefix $(DIST)/,$(IMG_FILES))

default:
	@echo "make build|clean|publish"

$(DIST)/$(MAIN_JS): $(ELM_FILES)
	@mkdir -p $(dir $@)
	elm-make --yes $(ELM_ENTRYPOINT) --output $@

$(DIST)/$(MAIN_MIN_JS): $(DIST)/$(MAIN_JS)
	uglifyjs $< -o $@

compile: $(DIST)/$(MAIN_JS)

# poor mans templating
$(DIST)/index.html: TIMESTAMP = $(shell date -r $(DIST)/$(MAIN_JS) +%s)
$(DIST)/index.html: dev.html $(DIST)/$(MAIN_JS)
	@mkdir -p $(dir $@)
	sed 's#/_compile/src/Main.elm#'$(MAIN_MIN_JS)?$(TIMESTAMP)'#' $< > $@

$(DIST)/css/%.css: css/%.css
	@mkdir -p $(dir $@)
	cp -a $< $@

$(DIST)/img/%: img/%
	@mkdir -p $(dir $@)
	cp -a $< $@


build: $(IMG_DIST) $(CSS_DIST) $(CSS_DIST_GZ) $(DIST)/$(MAIN_MIN_JS).gz $(DIST)/index.html

clean:
	rm -rf $(DIST)

clean-deps:
	rm -rf elm-stuff

publish: build
	couchapp push couch/ $(COUCHDB)

rsync: build
	rsync -av $(DIST)/ $(SERVER)

%.gz : %
	gzip -9fk $<

.PHONY: clean clean-deps publish default
