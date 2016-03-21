use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::DOM::Document;
use Encode;
use JSON::PS;

local $/ = undef;
my $doc = Web::DOM::Document->new;
$doc->manakai_is_html (1);
$doc->inner_html (decode 'utf-8', <>);

my $table = $doc->query_selector ('table:-manakai-contains("国・地域名"),
                                   table:-manakai-contains("English short name")')
    or die "Table not found";

sub _n ($) {
  my $s = shift;
  $s =~ s/\s+/ /g;
  $s =~ s/^ //;
  $s =~ s/ $//;
  return $s;
} # _n

sub pd ($) {
  my $s = shift;
  $s =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
  return decode 'utf-8', $s;
} # pd

my @row = @{$table->rows};
my $header = shift @row;
my @header;
for (@{$header->cells}) {
  push @header, _n $_->text_content;
}
my @data;
for (@row) {
  my @cell = @{$_->cells};
  my $row = {};
  for (0..$#cell) {
    $row->{$header[$_]} = $cell[$_];
  }
  push @data, $row;
}

my $Data = {};

for (@data) {
  my $code_cell = $_->{'二字'} || $_->{'Alpha-2 code'} || $_->{'alpha-2'} or next;
  my $name_cell = $_->{'国・地域名'} || $_->{'English short name (upper/lower case)'} or next;
  my $code = uc _n $code_cell->text_content;
  my $link = $name_cell->query_selector ('a:not(.image)');
  if (defined $link) {
    $Data->{$code}->{href} = $link->get_attribute ('href');
    if ($Data->{$code}->{href} =~ m{/wiki/([^/?#]+)}) {
      $Data->{$code}->{wref} = pd $1;
    }
  }
  my $img = $name_cell->query_selector ('a.image');
  if (defined $img) {
    $Data->{$code}->{flag_href} = $img->get_attribute ('href');
    if ($Data->{$code}->{flag_href} =~ m{/[^:/?#]+:([^:/?#]+\.svg)}) {
      $Data->{$code}->{flag_file_name} = 'File:' . pd $1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
