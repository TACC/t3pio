# $Id$
package FortranParserFactory;
use strict; use warnings;

sub instantiate {
    my $class          = shift;
    my $requested_type = shift;
    my $location       = "FortranParser/${requested_type}.pm";
    my $classFactory   = "FortranParser::$requested_type";

    require $location;

    return $classFactory->new(@_);
}

1;
