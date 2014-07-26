use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('lib')->stringify;
use IDs;
use JSON::PS;

my $Data = {};

my $root_path = path (__FILE__)->parent->parent;

## Names by Japanese government
{
  my $path = $root_path->child ('local/geonlp/countries.json');
  my $json = json_bytes2perl $path->slurp;

  for my $data (values %{$json->{areas}}) {
    my $id = IDs::get_id_by_string 'countries', $data->{ja_name};
    $Data->{areas}->{$id}->{$_} = $data->{$_}
        for qw(ja_name ja_short_name position);
  }
}

IDs::save_id_set 'countries';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
