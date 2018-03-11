#!/bin/sh
echo "1..14"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/countries.json | $jq -e "$2" > /dev/null && echo "ok $1") || echo "not ok $1"
}

test 1 '.areas["57"].code == "JP"'
test 2 '.areas["57"].en_name == "Japan"'
test 3 '.areas["57"].en_short_name == "Japan"'
test 4 '.areas["57"].ja_name == "日本国"'
test 5 '.areas["57"].ja_short_name == "日本"'
test 6 '.areas["57"].wref_ja == "日本"'
test 7 '.areas["57"].wref_en == "Japan"'
test 8 '.areas["57"].wikipedia_flag_file_name == "File:Flag_of_Japan.svg"'
test 9 '.areas["140"].gec == "KV"'
test 10 '.areas["140"].code != "XK"'
test 11 '.areas["140"].world_factbook_url == "https://www.cia.gov/library/publications/the-world-factbook/geos/kv.html"'
test 12 '.areas["296"].ja_name == "北マリアナ諸島"'
test 13 '.areas["296"].mofa_anzen_url == "http://www.anzen.mofa.go.jp/info/pcinfectionspothazardinfo_223.html"'
test 14 '.areas["122"].mofa_area_url == "http://www.mofa.go.jp/mofaj/area/hongkong/index.html"'
