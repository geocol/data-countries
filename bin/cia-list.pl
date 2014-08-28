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
$doc->manakai_set_url ('https://www.cia.gov/library/publications/the-world-factbook/appendix/appendix-d.html');

sub _n ($) {
  my $s = shift;
  $s =~ s/\s+/ /g;
  $s =~ s/^ //;
  $s =~ s/ $//;
  return $s;
} # _n

my $Data = [];

my $header = $doc->query_selector ('.header_ul');
my @header;
if (defined $header) {
  for (@{$header->query_selector_all ('td')}) {
    my $colspan = $_->colspan || 1;
    my $tc = $_->text_content;
    push @header, $tc;
    for (2..$colspan) {
      push @header, "$tc ($_)";
    }
  }
}

my $table = $doc->get_element_by_id ('GetAppendix_D')
    or die "No table";
for my $li (@{$table->children}) {
  next unless $li->local_name eq 'li';
  my $country = {};
  my $i = 0;
  for (@{$li->query_selector_all ('td.category_data, tr.category_data > td')}) {
    my $data = {};
    $data->{text_content} = _n $_->text_content;
    delete $data->{text_content} if $data->{text_content} eq '-';
    delete $data->{text_content} if not length $data->{text_content};
    my $link = $_->query_selector ('a');
    if (defined $link) {
      $data->{url} = $link->href;
      delete $data->{url} if $data->{url} eq q<https://www.cia.gov/library/publications/the-world-factbook/geos/-.html>;
    }
    $country->{$header[$i]} = $data;
    $i++;
  }
  push @$Data, $country;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
