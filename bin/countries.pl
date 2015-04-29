use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use CountryCodes;
use IDs;
use JSON::PS;

my $Data = {};
my $CodeToID = {};

my $root_path = $IDs::RootDirPath = path (__FILE__)->parent->parent;

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
    $CodeToID->{$d->{code}} = $id if defined $d->{code};

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
  $CodeToID->{GB} = $gb_id;
}

## Names by JP government
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
{
  my $path = $root_path->child ('src/jp-names.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    next if /^\s*#/;
    my ($id, $long_name, $short_name) = split /\s+/, $_, 3;
    next unless defined $id;
    $short_name //= $long_name;
    $Data->{areas}->{$id}->{ja_name} = $long_name;
    $Data->{areas}->{$id}->{ja_short_name} = $short_name;
  }
}

## Latitude and longitude by Google
{
  my $path = $root_path->child ('local/google-countries.json');
  my $json = json_bytes2perl $path->slurp;
  my $c2p = {};
  for (@$json) {
    $c2p->{$_->{country}} = [$_->{latitude}, $_->{longitude}];
  }
  for (values %{$Data->{areas}}) {
    if (defined $_->{code} and $c2p->{$_->{code}}) {
      $_->{position} = $c2p->{$_->{code}};
    }
  }
}

{
  my $path = $root_path->child ('local/iana-langtags.json');
  my $json = json_bytes2perl $path->slurp;

  for my $code (keys %{$json->{region}}) {
    next unless $code =~ /\A[a-z]{2}\z/;
    next unless $json->{region}->{$code}->{_registry}->{iana};
    next if $json->{region}->{$code}->{_deprecated};

    my $desc = $json->{region}->{$code}->{Description}->[0];
    next if $desc eq 'Private use';
    next unless CountryCodes::check_code uc $code;

    my $code = uc $code;
    my $id = IDs::get_id_by_string 'countries', $code;
    $Data->{areas}->{$id}->{code} = $code;
    if (defined $desc and length $desc) {
      $Data->{areas}->{$id}->{en_name} //= $desc;
      $Data->{areas}->{$id}->{en_short_name} //= $desc;
    }
    $CodeToID->{$code} = $id;
  }
}

{
  my $path = $root_path->child ('local/countries.json');
  my $json = json_bytes2perl $path->slurp;
  
  for my $data (@$json) {
    next unless CountryCodes::check_code $data->{cca2};
    my $id = IDs::get_id_by_string 'countries', $data->{cca2};
    my $d = $Data->{areas}->{$id} ||= {};
    for (
      [code => 'cca2'],
      [code3 => 'cca3'],
      [iso3166_numeric => 'ccn3'],
      [en_name => 'name'],
      [en_short_name => 'name'],
    ) {
      $d->{$_->[0]} ||= _n $data->{$_->[1]}
          if defined $data->{$_->[1]} and length $data->{$_->[1]};
    }

    if (defined $data->{region} and length $data->{region}) {
      if (my $code = {
        Africa => '002',
        Americas => '019',
        Asia => '142',
        Europe => '150',
        Oceania => '009',
      }->{$data->{region}}) {
        $d->{macroregion} = 0+$code;
      } else {
        warn "Unknown region |$data->{region}|";
      }
    }

    if (defined $data->{subregion} and length $data->{subregion}) {
      if (my $code = {
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
      }->{$data->{subregion}}) {
        $d->{submacroregion} = 0+$code;
      } else {
        warn "Unknown subregion |$data->{subregion}|";
      }
    }
  }
}

## CIA World Factbook
{
  my $path = $root_path->child ('local/cia-list.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@$json) {
    my $code = $data->{'ISO 3166'}->{text_content};
    my $id = defined $code ? $CodeToID->{$code} : undef;
    if (not defined $id) {
      $id = IDs::get_id_by_string 'countries', $code // $data->{Entity}->{text_content};
    }

    if (defined $data->{Entity}->{url}) {
      $Data->{areas}->{$id}->{world_factbook_url} = $data->{Entity}->{url};
    }
    if (defined $data->{GEC}->{text_content}) {
      $Data->{areas}->{$id}->{gec} = $data->{GEC}->{text_content};
    }
    if (defined $data->{Stanag}->{text_content}) {
      $Data->{areas}->{$id}->{stanag} = $data->{Stanag}->{text_content};
    }
    if (defined $data->{Entity}->{text_content}) {
      my $name = $data->{Entity}->{text_content};
      $Data->{areas}->{$id}->{en_name} ||= $name;
      $Data->{areas}->{$id}->{en_short_name} ||= $name;
    }
  }
}

## MOFA URLs
{
  my $path = $root_path->child ('local/mofa-anzen.json');
  my $json = json_bytes2perl $path->slurp;
  for my $name (keys %$json) {
    my $id = IDs::get_id_by_string 'countries', $name;
    $Data->{areas}->{$id}->{mofa_anzen_url} = $json->{$name};
    unless ($name eq 'タヒチ') {
      $Data->{areas}->{$id}->{ja_name} ||= $name;
      $Data->{areas}->{$id}->{ja_short_name} ||= $name;
    }
  }
}
{
  my $path = $root_path->child ('local/mofa-area.json');
  my $json = json_bytes2perl $path->slurp;
  for my $name (keys %$json) {
    my $id = IDs::get_id_by_string 'countries', $name;
    $Data->{areas}->{$id}->{mofa_area_url} = $json->{$name};
  }
}

## Wikipedia page names
{
  my $path = $root_path->child ('local/wikipedia-ja-countries.json');
  my $json = json_bytes2perl $path->slurp;
  for my $code (keys %$json) {
    my $id = $CodeToID->{$code} or do {
      warn "Code |$code| has no ID";
      next;
    };
    $Data->{areas}->{$id}->{wref_ja} = $json->{$code}->{wref}
        if defined $json->{$code}->{wref};
    $Data->{areas}->{$id}->{wikipedia_flag_file_name} = $json->{$code}->{flag_file_name}
        if defined $json->{$code}->{flag_file_name};
  }
}
{
  my $path = $root_path->child ('local/wikipedia-en-countries.json');
  my $json = json_bytes2perl $path->slurp;
  for my $code (keys %$json) {
    my $id = $CodeToID->{$code} or do {
      warn "Code |$code| has no ID";
      next;
    };
    $Data->{areas}->{$id}->{wref_en} = $json->{$code}->{wref}
        if defined $json->{$code}->{wref};
  }
}

$Data->{areas}->{431}->{en_name} ||= 'Hawaii';
$Data->{areas}->{431}->{en_short_name} ||= 'Hawaii';

## Historical
delete $Data->{areas}->{325}; # Netherlands Antilles
delete $Data->{areas}->{334}; # World
delete $Data->{areas}->{307}; # FX

IDs::save_id_set 'countries';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
