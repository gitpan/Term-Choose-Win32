use 5.010000;
use strict;
use warnings;
use Test::More tests => 1;

my $file = 'lib/Term/Choose/Win32.pm';

my $test_env = 0;
open my $fh1, '<', $file or die $!;
while ( my $line = readline $fh1 ) {
    if ( $line =~ /\A\s*use\s+warnings\s+FATAL/s ) {
        $test_env++;
    }
	if ( $line =~ /(?:\A\s*|\s+)use\s+Log::Log4perl/ ) {
		$test_env++;
	}
}
close $fh1;
is( $test_env, 0, "OK - test environment in $file disabled." );

