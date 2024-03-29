all: deps all-data

data: all-data

clean: clean-data

WGET = wget
CURL = curl -f
UNZIP = unzip
GIT = git
PERL = ./perl

updatenightly: autoupdate-deps dataautoupdate

autoupdate-deps: local/bin/pmbp.pl
	$(CURL) -s -S -L https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add bin/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config/perl/pmb-install.txt
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

dataautoupdate: clean deps all
	$(GIT) add data intermediate

## ------ Setup ------

deps: git-submodules pmbp-install json-ps

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl --install \
            --create-perl-command-shortcut perl \
            --create-perl-command-shortcut prove

json-ps: local/perl-latest/pm/lib/perl5/JSON/PS.pm
clean-json-ps:
	rm -fr local/perl-latest/pm/lib/perl5/JSON/PS.pm
local/perl-latest/pm/lib/perl5/JSON/PS.pm:
	mkdir -p local/perl-latest/pm/lib/perl5/JSON
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-json-ps/master/lib/JSON/PS.pm

local/bin/jq:
	mkdir -p local/bin
	$(WGET) -O $@ https://stedolan.github.io/jq/download/linux64/jq
	chmod u+x $@

## ------ Generation ------

all-data: data/countries.json data/macroregions.json
clean-data:
	rm -fr local/geonlp/*.zip local/geonlp/*.csv
	rm -fr local/geouk/*.html local/countries.json
	rm -fr local/iana-langtags.json
	rm -fr local/google-countries.csv
	rm -fr local/wikipedia-*.html local/cia-*.html local/mofa-*.html

local/geonlp/geonlp_world_country/geonlp_world_country_20130912_u.csv:
	mkdir -p local/geonlp
	$(WGET) -O local/geonlp/geonlp_world_country.zip https://geonlp.ex.nii.ac.jp/dictionary/geonlp/world_country/geonlp_world_country_20130912_u.zip
	cd local/geonlp && $(UNZIP) geonlp_world_country.zip
local/geonlp/geonlp_world_country.json: \
    local/geonlp/geonlp_world_country/geonlp_world_country_20130912_u.csv \
    bin/csv2json.pl
	$(PERL) bin/csv2json.pl $< > $@
local/geonlp/countries.json: local/geonlp/geonlp_world_country.json \
    bin/geonlp-countries.pl
	$(PERL) bin/geonlp-countries.pl $< > $@
	mkdir -p intermediate/geonlp
	cp local/geonlp/countries.json intermediate/geonlp/countries.json

local/govuk/names-index.html:
	mkdir -p local/govuk
	$(WGET) -O $@ https://www.gov.uk/government/publications/geographical-names-and-information
local/govuk/names/all.json: local/govuk/names-index.html \
    bin/extract-csv-urls.pl bin/csv2json.pl
	mkdir -p local/govuk/names
	$(PERL) bin/extract-csv-urls.pl "https://www.gov.uk" "local/govuk/names" $< | sh
	$(PERL) bin/csv2json.pl local/govuk/names/*.csv > $@

local/iana-langtags.json:
	mkdir -p local
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-web-defs/master/data/langtags.json

local/countries.json:
	mkdir -p local
	$(WGET) -O $@ https://raw.githubusercontent.com/mledoze/countries/master/countries.json

local/google-countries.csv:
	#$(WGET) -O $@ https://dspl.googlecode.com/hg/datasets/google/canonical/countries.csv
	cp src/google-countries.csv local/
local/google-countries.json: local/google-countries.csv bin/csv2json.pl
	$(PERL) bin/csv2json.pl $< > $@

local/wikipedia-ja-countries.html:
	$(WGET) -O $@ https://ja.wikipedia.org/wiki/ISO_3166-1
local/wikipedia-en-countries.html:
	$(WGET) -O $@ https://en.wikipedia.org/wiki/ISO_3166-1
local/wikipedia-ja-countries.json: local/wikipedia-ja-countries.html \
    bin/wikipedia-countries.pl
	$(PERL) bin/wikipedia-countries.pl $< > $@
local/wikipedia-en-countries.json: local/wikipedia-en-countries.html \
    bin/wikipedia-countries.pl
	$(PERL) bin/wikipedia-countries.pl $< > $@

local/cia-list.html:
	$(WGET) -O $@ https://www.cia.gov/library/publications/the-world-factbook/appendix/appendix-d.html
local/cia-list.json: local/cia-list.html bin/cia-list.pl
	$(PERL) bin/cia-list.pl $< > $@

local/mofa-anzen.html:
	$(CURL) https://www.anzen.mofa.go.jp/travel/ > $@
local/mofa-anzen.json: local/mofa-anzen.html bin/mofa-anzen.pl
	$(PERL) bin/mofa-anzen.pl $< > $@
local/mofa-area.html:
	$(CURL) https://www.mofa.go.jp/mofaj/area/ > $@
local/mofa-area.json: local/mofa-area.html bin/mofa-area.pl
	$(PERL) bin/mofa-area.pl $< > $@

data/countries.json: intermediate/geonlp/countries.json \
    local/govuk/names/all.json local/iana-langtags.json \
    local/countries.json local/google-countries.json \
    local/wikipedia-ja-countries.json local/wikipedia-en-countries.json \
    local/cia-list.json local/mofa-anzen.json local/mofa-area.json \
    src/wikipedia.txt \
    bin/countries.pl \
    bin/modules/generation/lib/IDs.pm intermediate/ids/countries.json
	$(PERL) bin/countries.pl > $@

data/macroregions.json: bin/macroregions.pl
	$(PERL) bin/macroregions.pl > $@

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps local/bin/jq

test-main:
	$(PROVE) t/*.t

## License: Public Domain.
