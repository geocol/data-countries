#!/bin/sh
echo "1..5"
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
