use 5.010000;
use warnings;
use strict;
die "No support for OS" if $^O ne 'MSWin32';
use Module::Build;


my $builder = Module::Build->new(
    module_name         => 'Term::Choose::Win32',
    license             => 'perl',
    dist_author         => 'Matthaeus Kiem <cuer2s@gmail.com>',
    dist_version_from   => 'lib/Term/Choose/Win32.pm',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
         'perl'                => '5.010000',
        'Carp'                 => 0,
        'Term::Size::Win32'    => '0.209',
        'Term::Choose'         => '1.061',
        'Unicode::GCString'    => '2012.10',
        'Win32::Console'       => '0.09',
        'Win32::Console::ANSI' => '1.06',
    },
    add_to_cleanup      => [ 'Term-Choose-Win32-*' ],
    #create_makefile_pl => 'traditional',
);

$builder->create_build_script();
