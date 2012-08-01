# $Id$
package FortranParser::Free;
use strict;
use base qw(FortranParser::Base);
sub new
{
  my ($classH) = @_;

  my $selfH = bless {}, $classH;

  return $selfH;
}

sub parse
{
  my $self = shift;
  my ($fn,$result) = @_;
  my @whole;

  FortranParser::Base::readFile($fn,\@whole);

  my @stage1;
  for $_ (@whole)
    {
      chomp $_;
      my $line = FortranParser::Base::remove_comments($_);
      my @line = split("\n", $line);
      push(@stage1, @line);
    }

  FortranParser::Base::joinF90ContinuationLines(\@stage1, $result);

}

1;
