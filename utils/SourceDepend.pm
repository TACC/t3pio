# $Id$
package SourceDepend;
use strict;
my %incT;

sub new
{
  my $class                = shift;
  my ($fn, $file, $parser) = @_;
  my $self                 = {};
  $self->{'fn'}            = $fn;
  $self->{'file'}          = $file;
  $self->{'parser'}        = $parser;
  $self->{'myIncT'}        = {};
  $self->{'myUseT'}        = {};
  $self->{'myModuleT'}     = {};
  bless $self;
}

sub stripMe
{
  my $name  = shift;
  my $strip = $main::opt_strip;
  if ($strip)
    {
      $name =~ s/.*\///;
    }
  return $name;
}
sub removeExt
{
  my ($path) = @_;
  my $result = ($path =~ /(.*)\./) ? $1 : $path;
  return $result;
}

sub find_includes
{
  my $self     = shift;
  my $tbl      = shift;
  my $fn       = $self->{'fn'};
  my $bareFN   = $fn;
  my @lineA;
  my $caseFunc = $tbl->{'case'};


  if ($fn =~ m|.*/(.*)|)
    {
      my $bareName = $1;
      my $results  = main::findSrc($bareName,\@main::incdirs);
      $bareFN = $bareName if ($results ne "");
    }

  $self->{'parser'}->parse($fn,\@lineA);

  for $_ (@lineA)
    {
      my $name;
      my $found = 0;

      ########################################
      # Search for include statements

      if ($_ =~ /^\s*include\s*['"]([^"']*)["']/i)
        {
          $name  = $1;
	  $found = ! exists $main::ignoreT{$name};
        }
      elsif ($_ =~ /^\s*#\s*include\s*["]([^"]*)["]/)
        {
          $found = 1;
          $name  = $1;
        }
      if ($found)
        {
          # Search this file if we have not seen it
          if (! exists $incT{$name})
            {
              my $incFn    = main::findSrc($name,\@main::incdirs);
              my $incF     = $self->new($incFn, $name, $self->{'parser'});
              $incT{$name} = $incF;
              if ( $incFn eq "")
                {
                  print STDERR "Unable to find: \"$name\"\n";
                }
              else
                {
                  $incF->find_includes();
                }
            }
          $self->{'myIncT'}{$name} = 1;
          next;
        }

      ############################################
      # Search for line directives from CPP output

      if ($_ =~ /^#line \d+ "([^"]+)"/ || $_ =~ /^# \d+ "([^"]+)"/ )
        {
          $name = $1;
          if ($name =~ m|.*/(.*)|)
            {
              my $bareName = $1;
              my $results  = main::findSrc($bareName,\@main::incdirs);
              $name = $bareName if ($results ne "");
            }
          if ($name ne $bareFN && $name !~ /^</)
            { $self->{'myIncT'}{$name} = 1; }
        }


      ########################################
      # Search for use statements

      if ($_ =~ /^\s*use\s+(\w+)/i)
        {
          $name = $1;
          $name = $caseFunc->($name);
          $self->{'myUseT'}{$name} = 1 if (! exists $main::ignoreT{lc($name)});
          next;
        }

      ########################################
      # Search for module statements

      if ($_ =~ /^\s*module\s+(\w+)/i)
        {
          $name = $1;
          next if ($name =~ /\bprocedure\b/i);
          $name = $caseFunc->($name);
          $self->{'myModuleT'}{$name} = 1;
        }
    }
}

sub extract
{
  my @a;
  my $name;
  my $self   = shift;
  my $tbl    = shift;
  my $prefix = $main::prefix;
  my $strip  = $main::opt_strip;
  my $obj_ext = "." . $tbl->{'obj_ext'};
  my $mod_ext = "." . $tbl->{'mod_ext'};
  my $obj_prefix = $main::obj_prefix;
  my $mod_prefix = $main::mod_prefix;

  $obj_prefix = $prefix if ($obj_prefix eq "");
  $mod_prefix = $prefix if ($mod_prefix eq "");


  push(@a, $obj_prefix . stripMe(removeExt($self->{'file'})) . $obj_ext);

  ########################################
  # Modules
  for $name (sort keys(%{$self->{'myModuleT'}}))
    { push(@a, $mod_prefix . stripMe($name) . $mod_ext) }

  push(@a, ":");

  ########################################
  # Write the source file first

  $name = $self->{'file'};
  push (@a, $name);

  ########################################
  # Use Module List
  for $name (sort keys(%{$self->{'myUseT'}}))
    {
      if (! exists $self->{'myModuleT'}{$name})
        { push(@a, $mod_prefix . stripMe($name) . $mod_ext) }
    }

  ########################################
  # include file list

  my %a;

  for $name (sort keys(%{$self->{'myIncT'}}))
    {
      $a{$name} = 1;
      for my $n (sort keys(%incT))
        { $a{$n} = 1; }
    }
  push (@a, (keys %a));

  return join(" ",@a);
}


1;
