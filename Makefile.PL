

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CGI::Perljax',
    VERSION_FROM => 'lib/CGI/Perljax.pm', # finds \$VERSION
    AUTHOR       => 'Brian C. Thomas (bcthomas@nature.berkeley.edu)',
    ABSTRACT     => 'CGI::Perljax',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Class::Accessor' => 0,
                     'CGI' => 0
                    },
);
