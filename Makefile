all: deps all-data

WGET = wget
CURL = curl
UNZIP = unzip
GIT = git
PERL = ./perl

updatenightly: local/bin/pmbp.pl
	$(CURL) -s -S -L https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add modules t_deps/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config

## ------ Setup ------

deps: git-submodules pmbp-install json-ps

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
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

## ------ Generation ------

all-data: data/country-names.json
clean-data:
	rm -fr local/geonlp/*.zip local/geonlp/*.csv
	rm -fr local/geouk/*.html

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

data/country-names.json: intermediate/geonlp/countries.json \
    local/govuk/names/all.json \
    bin/country-names.pl
	$(PERL) bin/country-names.pl > $@

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
	$(PROVE) t/*.t