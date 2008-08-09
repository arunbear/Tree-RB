use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tree::RB',
    AUTHOR              => 'Arun Prasad <arunbear@cpan.org>',
    VERSION_FROM        => 'lib/Tree/RB.pm',
    ABSTRACT_FROM       => 'lib/Tree/RB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'enum'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tree-RB-*' },
);
