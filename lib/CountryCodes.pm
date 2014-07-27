package CountryCodes;
use strict;
use warnings;

sub check_code ($) {
  return 0 unless defined $_[0];
  return 0 unless length $_[0];
  return 0 unless $_[0] =~ /\A[A-Za-z]{2}\z/;
  return not {
    #AC => 1, CP => 1, DG => 1, EA => 1, IC => 1, TA => 1,
    EU => 1, FX => 1, SU => 1, UK => 1,
    AN => 1, BU => 1, CS => 1, NT => 1, SF => 1, TP => 1, YU => 1, ZR => 1,
    XK => 1,
  }->{uc $_[0]};
} # check_code

1;

## License: Public Domain.
