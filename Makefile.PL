use 5.010000;
use warnings;
use strict;
die "No support for OS" if $^O ne 'MSWin32';
use ExtUtils::MakeMaker;


WriteMakefile(
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010000',
    LICENSE          => 'perl',
    AUTHOR           => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME             => 'Term::Choose::Win32',
    VERSION_FROM     => 'lib/Term/Choose/Win32.pm',
    EXE_FILES        => [],
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'                 => 0,
        'Exporter'             => 0,
        'Term::Size::Win32'    => '0.209',
        'Term::Choose'         => '1.067',
        'Unicode::GCString'    => '2013.10',
        'Win32::Console'       => '0.09',
        'Win32::Console::ANSI' => '1.06',
    },
    clean => {
        FILES => 'Term-Choose-Win32-*',
    },
);
