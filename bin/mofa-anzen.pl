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

sub _n ($) {
  my $s = shift;
  $s =~ s/\s+/ /g;
  $s =~ s/^ //;
  $s =~ s/ $//;
  return $s;
} # _n

my $Data = {};

for (@{$doc->query_selector_all ('option[value^="http://"]')}) {
  my $url = $_->value;
  $url =~ s/\#.*$//;
  my $name = _n $_->text_content;
  $name =~ s/^\x{25BC}//;
  $Data->{$name} = $url;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
