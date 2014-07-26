package IDs;
use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;
my $json_dir_path = $root_path->child ('intermediate/ids');
my $src_path = $root_path->child ('src/ids');

my $IDSets = {};

sub load ($) {
  my $set_name = shift;
  return if $IDSets->{$set_name};

  my $json_path = $json_dir_path->child ($set_name . '.json');
  if ($json_path->is_file) {
    $IDSets->{$set_name} = json_bytes2perl $json_path->slurp;
  } else {
    $IDSets->{$set_name} = {};
  }
} # load

sub get_id_by_string ($$) {
  my ($set_name, $string) = @_;
  load $set_name;
  my $id = $IDSets->{$set_name}->{$string};
  return $id if defined $id;
  
  $id = 1;
  for (values %{$IDSets->{$set_name}}) {
    $id = $_ + 1 if $_ >= $id;
  }

  $IDSets->{$set_name}->{$string} = $id;
  return $id;
} # get_id_by_string

sub save_id_set ($) {
  my $set_name = shift;
  return unless defined $IDSets->{$set_name};

  my $json_path = $json_dir_path->child ($set_name . '.json');
  $json_path->spew (perl2json_bytes_for_record $IDSets->{$set_name});
} # save_id_set

1;

## License: Public Domain.
