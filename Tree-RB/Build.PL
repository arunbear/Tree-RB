use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tree::RB',
    license             => 'perl',
    dist_author         => 'Arun Prasad <arunbear@cpan.org>',
    dist_version_from   => 'lib/Tree/RB.pm',
    requires => {
        'Test::More' => 0,
        'enum'       => 0,
    },
    add_to_cleanup      => [ 'Tree-RB-*' ],
);

$builder->create_build_script();
