use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('lib')->stringify;
use CountryCodes;
use IDs;
use JSON::PS;
use Path::Tiny;

my $Data = {};

my $regions = {
        World => '001',

        Africa => '002',
        Americas => '019',
        Asia => '142',
        Europe => '150',
        Oceania => '009',

        'Eastern Africa' => '014',
        'Middle Africa' => '017',
        'Northern Africa' => '015',
        'Southern Africa' => '018',
        'Western Africa' => '011',
        'Caribbean' => '029',
        'Central America' => '013',
        'Northern America' => '021',
        'South America' => '005',
        'Central Asia' => '143',
        'Eastern Asia' => '030',
        'South-Eastern Asia' => '035',
        'Southern Asia' => '034',
        'Western Asia' => '145',
        'Eastern Europe' => '151',
        'Northern Europe' => '154',
        'Southern Europe' => '039',
        'Western Europe' => '155',
        'Australia and New Zealand' => '053',
        'Melanesia' => '054',
        'Micronesia' => '057',
        'Polynesia' => '061',

        'Latin America and the Caribbean' => '419',
};

for (keys %$regions) {
  $Data->{areas}->{0+$regions->{$_}}->{code} = ''.$regions->{$_};
  $Data->{areas}->{0+$regions->{$_}}->{en_name} = $_;
}

for (
  ['001' => qw(002 019 142 150 009)],
  ['002' => qw(014 017 015 018 011)],
  ['019' => qw(419 021)],
  ['419' => qw(029 013 005)],
  ['142' => qw(143 030 034 035 145)],
  ['150' => qw(151 154 039 155)],
  ['009' => qw(053 054 057 061)],
) {
  my ($parent, @child) = @$_;
  $Data->{areas}->{0+$parent}->{subregions}->{0+$_} = 1 for @child;
}

{
  my $path = path (__FILE__)->parent->parent->child ('local/countries.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@$json) {
    next unless CountryCodes::check_code $data->{cca2};
    if (defined $data->{subregion} and length $data->{subregion}) {
      if (defined $regions->{$data->{subregion}}) {
        my $country_id = IDs::get_id_by_string 'countries', $data->{cca2};
        $Data->{areas}->{0+$regions->{$data->{subregion}}}->{countries}->{$country_id} = 1;
      } else {
        warn "Unknown subregion |$data->{subregion}|";
      }
    }
  }
}

{
  my $changed = 0;
  for my $id (keys %{$Data->{areas}}) {
    for (keys %{$Data->{areas}->{$id}->{subregions} or {}}) {
      for (keys %{$Data->{areas}->{$_}->{countries} or {}}) {
        unless ($Data->{areas}->{$id}->{countries}->{$_}) {
          $Data->{areas}->{$id}->{countries}->{$_} = 1;
          $changed = 1;
        }
      }
    }
  }
  redo if $changed;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
