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

sub check_code ($) {
  return not {
    #AC => 1, CP => 1, DG => 1, EA => 1, IC => 1, TA => 1,
    EU => 1, FX => 1, SU => 1, UK => 1,
    AN => 1, BU => 1, CS => 1, NT => 1, SF => 1, TP => 1, YU => 1, ZR => 1,
    XK => 1,
  }->{uc shift};
} # check_code

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

{
  my $path = $root_path->child ('local/iana-langtags.json');
  my $json = json_bytes2perl $path->slurp;

  for my $code (keys %{$json->{region}}) {
    next unless $code =~ /\A[a-z]{2}\z/;
    next unless $json->{region}->{$code}->{_registry}->{iana};
    next if $json->{region}->{$code}->{_deprecated};

    my $desc = $json->{region}->{$code}->{Description}->[0];
    next if $desc eq 'Private use';
    next unless check_code uc $code;

    my $code = uc $code;
    my $id = IDs::get_id_by_string 'countries', $code;
    $Data->{areas}->{$id}->{code} = $code;
    if (defined $desc and length $desc) {
      $Data->{areas}->{$id}->{en_name} //= $desc;
      $Data->{areas}->{$id}->{en_short_name} //= $desc;
    }
  }
}

{
  my $path = $root_path->child ('local/countries.json');
  my $json = json_bytes2perl $path->slurp;
  
  for my $data (@$json) {
    next unless check_code $data->{cca2};
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
  }
}

IDs::save_id_set 'countries';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
