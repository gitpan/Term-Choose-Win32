use 5.010000;
use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use Test::More tests => 3;


my $v            = -1;
my $v_pod        = -1;
my $v_changes    = -1;
my $release_date = -1;

open my $fh1, '<', catfile( 'lib', 'Term', 'Choose', 'Win32.pm' ) or die $!;
while ( my $line = readline $fh1 ) {
    if ( $line =~ /^our\ \$VERSION\ =\ '(\d\.\d\d\d)';/ ) {
        $v = $1;
    }
    if ( $line =~ /\A=pod/ .. $line =~ /\A=cut/ ) {
        if ( $line =~ m/\A\s*Version\s+(\S+)/m ) {
            $v_pod = $1;
        }
    }
}
close $fh1;

open my $fh_ch, '<', catfile( 'Changes' ) or die $!;
while ( my $line = readline $fh_ch ) {
    if ( $line =~ m/\A\s*([0-9][0-9.]*)\s+(\d\d\d\d-\d\d-\d\d)\s*\Z/m ) {
        $v_changes = $1;
        $release_date = $2;
        last;
    }
}
close $fh_ch;

use Time::Piece;
my $t = localtime;
my $today = $t->ymd;


is( $v,            $v_pod,         'Version in POD Term::Choose OK' );
is( $v,            $v_changes,     'Version in "Changes" OK' );
is( $release_date, $today,         'Release date in Changes is date from today' );


