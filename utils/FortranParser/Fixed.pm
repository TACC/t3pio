# $Id$
package FortranParser::Fixed;
use strict;
use base qw(FortranParser::Base);
sub new
{
  my ($classH) = @_;

  my $self = bless {}, $classH;

  return $self;
}

sub parse
{
  my $self         = shift;
  my ($fn,$result) = @_;
  my @whole;

  FortranParser::Base::readFile($fn,\@whole);

  my @stage1;
  for $_ (@whole)
    {
      chomp $_;
      next if ($_ =~ /^[!*cCdD]/);
      my $line = FortranParser::Base::remove_comments($_);
      my @line = split("\n", $line);
      push(@stage1, @line);
    }

  FortranParser::Base::joinF77ContinuationLines(\@stage1,$result);
}

1;
