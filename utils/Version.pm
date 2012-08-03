package Version;
use strict;
sub number()
{
  return "1.3.2";
}
sub name()
{
  my $v = number();
  return "Version $v: 2011-11-16 11:48";
}
1;
