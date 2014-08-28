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
$doc->manakai_set_url (q<http://www.mofa.go.jp/mofaj/area/>);

sub _n ($) {
  my $s = shift;
  $s =~ s/\s+/ /g;
  $s =~ s/^ //;
  $s =~ s/ $//;
  return $s;
} # _n

my $Data = {};

for my $el ($doc->get_element_by_id ('sidebar')) {
  next unless defined $el;
  $el->parent_node->remove_child ($el);
}

for (@{$doc->query_selector_all ('.styled2 > a[href$="/index.html"]')}) {
  my $url = $_->href;
  my $name = _n $_->text_content;
  $Data->{$name} = $url;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
