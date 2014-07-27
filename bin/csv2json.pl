use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my @Data;

my @file_name = @ARGV or die "No file name";

for my $file_name (@file_name) {
  my @data;
  for (split /\x0D?\x0A/, path ($file_name)->slurp_utf8) {
    next if /^#/;
    next if /^$/;
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
  for (@$header) {
    s/\s+/ /g;
    s/^ //;
    s/ $//;
  }
  $file_name =~ m{([^/]+)$};
  my $f = $1;

  for my $data (@data) {
    my $new_data = {};
    $new_data->{$header->[$_]} = $data->[$_] for 0..$#$data;
    $new_data->{__source_file} = $f;
    push @Data, $new_data;
  }
}

print perl2json_bytes_for_record \@Data;

## License: Public Domain.
