use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('lib')->stringify;
use IDs;
use JSON::PS;

my $Data = {};

my $root_path = path (__FILE__)->parent->parent;

sub _n ($) {
  my $s = shift;
  $s =~ s/\s+/ /g;
  $s =~ s/^ //;
  $s =~ s/ $//;
  return $s;
}

## Names by UK government
{
  my $path = $root_path->child ('local/govuk/names/all.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@$json) {
    my $key = $data->{'The two-letter ISO 3166-1 code'};
    unless (defined $key and length $key) {
      #warn "No two-letter code for |$data->{Country}|";
      $key = $data->{Country} || $data->{'Geographic Location'};
    }
    my $id = IDs::get_id_by_string 'countries', $key;
    my $d = $Data->{areas}->{$id} ||= {};
    for (
      [code => 'The two-letter ISO 3166-1 code'],
      [code3 => 'The three-letter ISO 3166-1 code'],
      [en_name => 'Official Name'],
      [en_short_name => 'Country'],
    ) {
      $d->{$_->[0]} = _n $data->{$_->[1]}
          if defined $data->{$_->[1]} and length $data->{$_->[1]};
    }
    $d->{en_short_name} = $data->{'Geographic Location'}
        if not defined $d->{en_short_name};

    if ($data->{__source_file} =~ /Country_Names/) {
      $d->{status}->{gb} = 'country';
    } elsif ($data->{__source_file} =~ /UK_Overseas_Territory_Names/) {
      #$d->{status}->{gb} = 'overseas territory';
      $d->{status}->{gb} = 'other';
    } elsif ($data->{__source_file} =~ /Other_Geographical_Names/) {
      $d->{status}->{gb} = 'other';
    }
  }

  my $gb_id = IDs::get_id_by_string 'countries', 'GB';
  $Data->{areas}->{$gb_id}->{en_name} = 'The United Kingdom of Great Britain and Northern Ireland';
  $Data->{areas}->{$gb_id}->{en_short_name} = 'United Kingdom';
  $Data->{areas}->{$gb_id}->{code} = 'GB';
  $Data->{areas}->{$gb_id}->{code3} = 'GBR';
  $Data->{areas}->{$gb_id}->{status}->{gb} = 'country';
}

## Names by Japanese government
{
  my $path = $root_path->child ('intermediate/geonlp/countries.json');
  my $json = json_bytes2perl $path->slurp;

  for my $data (values %{$json->{areas}}) {
    my $id = IDs::get_id_by_string 'countries', $data->{ja_name};
    $Data->{areas}->{$id}->{$_} = $data->{$_}
        for qw(ja_name ja_short_name position);

    if (defined $data->{jp_status}) {
      $Data->{areas}->{$id}->{status}->{jp} = $data->{jp_status};
    }
  }
}

IDs::save_id_set 'countries';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
