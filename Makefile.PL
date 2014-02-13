use 5.010001;
use warnings;
use strict;
die "No support for OS" if $^O ne 'MSWin32';
use ExtUtils::MakeMaker;


WriteMakefile(
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010001',
    LICENSE          => 'perl',
    AUTHOR           => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME             => 'Term::Choose::Win32',
    VERSION_FROM     => 'lib/Term/Choose/Win32.pm',
    EXE_FILES        => [],
    BUILD_REQUIRES   => {
        'Test::More'           => 0,
    },
    PREREQ_PM => {
        'constant'             => 0,
        'strict'               => 0,
        'warnings'             => 0,
        'Carp'                 => 0,
        'Exporter'             => 0,
        'Term::Size::Win32'    => 0,
        'Term::Choose'         => 0,
        'Unicode::GCString'    => 0,
        'Win32::Console'       => 0,
        'Win32::Console::ANSI' => 0,
    },
    clean => {
        FILES => 'Term-Choose-Win32-*',
    },
);
