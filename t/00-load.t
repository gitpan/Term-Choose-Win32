use 5.010000;
use strict;
use warnings;
use Test::More tests => 1;


BEGIN {
    use_ok( 'Term::Choose::Win32' ) || print "Bail out!\n";
}

diag( "Testing Term::Choose::Win32 $Term::Choose::Win32::VERSION, Perl $], $^X" );
