use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $file_name = shift or die "No file name";

my @data;
for (split /\x0D?\x0A/, path ($file_name)->slurp_utf8) {
  my @line;
  while (length) {
    if (s/^((?>[^,"]+|"[^"]*"?)+)//) {
      my $d = $1;
      if ($d =~ s/^"//) {
        $d =~ s/"$//;
        $d =~ s/""/"/g;
        push @line, $d;
      } else {
        push @line, $d;
      }
      s/^,//;
    } elsif (s/^,//) {
      push @line, '';
    }
  }
  push @data, \@line;
}

my $header = shift @data;

my @Data;
for my $data (@data) {
  my $new_data = {};
  $new_data->{$header->[$_]} = $data->[$_] for 0..$#$data;
  push @Data, $new_data;
}

print perl2json_bytes_for_record \@Data;

## License: Public Domain.
