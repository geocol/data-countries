use strict;
use warnings;
use utf8;
use JSON::PS;

local $/ = undef;
my $Input = json_bytes2perl <>;

my $Data = {};

my $short_names = {};
for my $input (@$Input) {
  my $short_name = $input->{body};
  $short_names->{$short_name}++;
}

for my $input (@$Input) {
  my $d1 = '';
  my $d2 = '';
  $d1 = '・' if $input->{prefix} =~ /\p{Kana}$/ and $input->{body} =~ /^\p{Kana}/;
  $d2 = '・' if $input->{body} =~ /\p{Kana}$/ and $input->{suffix} =~ /^\p{Kana}/;
  my $name = $input->{prefix} . $d1 . $input->{body} . $d2 . $input->{suffix};
  $name =~ s{^/}{};
  $name =~ s{/$}{};
  $name =~ s/^北(?=朝鮮民主主義人民共和国)//;
  $name =~ s/^台湾$/中華民国/;

  my $short_name = $short_names->{$input->{body}} > 1
      ? $name : $input->{body};
  $short_name = '北朝鮮' if $name eq '朝鮮民主主義人民共和国';
  $short_name = '台湾' if $name eq '中華民国';
  $short_name = '韓国' if $name eq '大韓民国';
  $short_name = '中国' if $name eq '中華人民共和国';
  $short_name = $name if $short_name eq 'アラブ';
  #$short_name = $name if $short_name eq 'マケドニア';
  $short_name = $name if $input->{suffix} eq q{諸島/};
  #$short_name =~ s/及び/および/;
  $short_name = '英国' if $short_name eq 'グレートブリテン及び北アイルランド連合王国';

  my $key = join ' ', $input->{latitude}, $input->{longitude};
  if ($Data->{areas}->{$key}) {
    next if length $Data->{areas}->{$key}->{ja_name} > length $name;
  }

  $Data->{areas}->{$key}->{ja_short_name} = $short_name;
  $Data->{areas}->{$key}->{ja_name} = $name;
  $Data->{areas}->{$key}->{position} = [$input->{latitude}, $input->{longitude}];
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
