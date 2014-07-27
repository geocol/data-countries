use strict;
use warnings;
use Path::Tiny;

my $url_prefix = shift;
my $output_path = shift;

local $/ = undef;
my $data = <>;

while ($data =~ m{<a\s+href="([^"]+?\.csv)">}g) {
  my $url = $1;
  $url = $url_prefix . $url if $url =~ m{^/};
  $url =~ m{([^/]+)$};
  my $file_name = $1;
  print "wget -O $output_path/$file_name $url\n";
}

## License: Public Domain.
