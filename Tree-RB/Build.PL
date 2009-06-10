use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tree::RB',
    license             => 'perl',
    dist_author         => 'Arun Prasaad <arunbear@cpan.org>',
    dist_version_from   => 'lib/Tree/RB.pm',
    requires => {
        'Test::More' => 0,
        'enum'       => 0,
    },
    add_to_cleanup      => [ 'Tree-RB-*' ],
    create_makefile_pl  => 'passthrough',
    meta_merge => {
        resources => {
            repository => 'http://github.com/arunbear/perl5-red-black-tree',
        }
    },
);

$builder->create_build_script();
