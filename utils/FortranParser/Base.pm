# $Id$
package FortranParser::Base;
use strict;
use FileHandle;
sub new
{
  my ($classBase) = @_;
  my $selfBase    = bless {}, $classBase;
  return $selfBase;
}

sub readFile
{
  my ($fn, $rA) = @_;

  if ( -f $fn)
    {
      my $fh = FileHandle->new($fn,"r");
      @$rA = <$fh>;
      $fh->close();
    }
  else
    {
      print STDERR "Unable to find \"$fn\"\n";
      @$rA = ("");
    }
}


sub findCmdInPath
{
  my ($cmd, $path) = @_;
  my $undef;

  undef $undef;

  if ($cmd =~ /^\//)
    {
      my $result = (-x $cmd) ? $cmd : $undef;
      return $result;
    }

  my @path = split(":",$path);

  my $result;
  for $_ (@path)
    {
      $result = "$_/$cmd";
      if ( -x $result)
        { return $result; }
    }
  return $undef;
}

sub readCPP
{
  my ($fn,$rA) = @_;

  my $path = "/usr/ccs/lib:" . $ENV{PATH};
  my $cmd = findCmdInPath($main::cpp_prog,$path);
  if (! defined $cmd)
    {
      readFile($fn, $rA);
      return;
    }
  else
    {
      open (CMD,
            "($cmd --version) 2>&1 < /dev/null |");
      my @results = <CMD>;
      close (CMD);
      my $results = join(" ",@results);
      if ($results =~ /Free Software Foundation/m)
        { $cmd = "$cmd -w "; }

      my @cmd;
      push(@cmd, $cmd);
      for $_ (@main::defines)
        { push(@cmd, "-D$_"); }
      for $_ (@main::incdirs)
        { push(@cmd, "-I$_"); }
      push(@cmd, $fn);
      $cmd = join (" ", @cmd);
      #print "$cmd\n";

      open (CMD, "($cmd ) 2>&1 |");

      @$rA = <CMD>;
      close(CMD);
    }
}


sub remove_comments
{
  my ($line)   = @_;
  my $quote    = 0;
  my $qchar    = '';
  my $loc      = 0;
  my $leftover = $line;

  $_  = '';
  $line =~ m/(^\s*)\S/;

  my $leadingS = $1;

  while($leftover =~ m/['";!]/g )
    {
      my $loc = pos($leftover)-1;
      my $c   = substr $leftover, $loc, 1;

      if ($quote and $c eq $qchar)
	{
	  $quote = 0;
	  $qchar = '';
	}
      elsif ($c =~ /['"]/)
	{
	  $qchar = $c;
	  $quote = 1;
	}
      elsif (! $quote && $c eq "!")
	{
	  $_        = substr $leftover, 0, $loc;
	  $leftover = '';
	  last;
	}
      elsif (! $quote && $c eq ";")
	{
	  $_       .= substr $leftover, 0, $loc;
	  $_       .= "\n" . $leadingS;
          $leftover = ($loc+2 <= length($leftover)) ? substr $leftover, $loc+2 : "";
	}
    }

  $_ .= $leftover;

  s/\s+$//;

  return $_;
}


sub joinF90ContinuationLines
{
  my ($stage1, $result) = @_;

  ############################################################
  # Join continuation lines

  my $num = @$stage1;  # get array size;

  my $i	      = 0;
  my $prev    = "";
  my $prevFlg = 0;
  my $j	      = 0;
  while($i < $num)
    {
      $_	    = $stage1->[$i];
      my $cur	    = ($_ =~ /^\s*&(.*)/) ? $1 : $_;
      my $curFlg    = (m/&$/g);
      $_	    = $prev . $cur if ($prevFlg);
      $result->[$j] = $_;

      if ($curFlg)
	{ $prev = substr $_, 0, length($_)-1; }
      else
	{
	  $j++;
	  $prev = $_;
	}
      $prevFlg = $curFlg;
      $i++;
    }
}

sub joinF77ContinuationLines
{
  my ($stage1, $result) = @_;
  ############################################################
  # Join continuation lines

  my $num = @$stage1;  # get array size;

  my $i	      = 0;
  my $prev    = "";
  my $prevFlg = 0;
  my $j	      = 0;
  while($i < $num)
    {
      $_	    = $stage1->[$i++];
      while ($i < $num)
        {
          my $nextL = $stage1->[$i];
          if ($nextL =~ /^     [^ 0](.*)/)
            {
              $_      .= $1;
              $i++;
            }
          else
            { last; }
        }
      push(@$result,$_)
    }
}
1;

