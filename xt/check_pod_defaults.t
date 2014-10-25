use 5.010000;
use strict;
use warnings;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use Test::More;

my @long = ( qw( pad pad_one_row empty undef ll default limit screen_width lf keep ) );
my @simple = ( qw( justify layout order clear_screen page mouse beep hide_cursor index ) ); # prompt
my @all = ( @long, @simple );
my @deprecated = ( qw(st) );

plan tests => 2 + scalar @all;


my $file = 'lib/Term/Choose/Win32.pm';
my $fh;
my %option_default;

open $fh, '<', $file or die $!;
while ( my $line = readline $fh ) {
    if ( $line =~ /\Asub _set_defaults {/ .. $line =~ /\A\s+return\s\$config;/ ) {
        if ( $line =~ m|\A\s+#?\s*\$config->{(\w+)}\s+//=\s(.*);| ) {
            my $op = $1;
            next if $op eq 'prompt';
            next if $op ~~ @deprecated;
            $option_default{$op} = $2;
         }
    }
}
close $fh;


my %pod_default;
my %pod;

for my $key ( @all ) {
    next if $key ~~ @deprecated;
    open $fh, '<', $file or die $!;
    while ( my $line = readline $fh ) {
        if ( $line =~ /\A=head4\s\Q$key\E/ ... $line =~ /\A=head/ ) {
            chomp $line;
            next if $line =~ /\A\s*\z/;
            push @{$pod{$key}}, $line;
        }
    }
    close $fh;
}

for my $key ( @simple ) {
    next if $key ~~ @deprecated;
    my $opt;
    for my $line ( @{$pod{$key}} ) {
        if ( $line =~ /(\d).*\(default\)/ ) {
            $pod_default{$key} = $1;
            last;
        }
    }
}

for my $key ( @long ) {
    next if $key ~~ @deprecated;
    if ( $key eq 'pad_one_row' ) {
        for my $line ( @{$pod{$key}} ) {
            if ( $line =~ /default:\s([^)]+)\)/ ) {
                $pod_default{$key} = $1;
                last;
            }
        }
    }
    else {
        for my $line ( @{$pod{$key}} ) {
            if ( $line =~ /default:\s('[^']+'|\w+)(?:\)|\s*)/ ) {
                $pod_default{$key} = $1;
                last;
            }
        }
    }
}



is( scalar @all, scalar keys %option_default, 'scalar @all == scalar keys %option_default' );
is( scalar keys %pod_default, scalar keys %option_default, 'scalar keys %pod_default == scalar keys %option_default' );


for my $key ( sort keys %option_default ) {
    next if $key ~~ @deprecated;
    if ( $key eq 'pad_one_row' ) {
        my $por = 0;
        if ( $option_default{$key} eq '$config->{pad}' and $pod_default{$key} eq 'value of the option I<pad>' ) {
            $por = 1;
        }
        is( $por, '1', "option $key: default value in pod OK" );
    }
    else {
        is( $option_default{$key}, $pod_default{$key}, "option $key: default value in pod matches default value in code" );
    }
}


