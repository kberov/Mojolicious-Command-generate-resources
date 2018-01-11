

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Mojolicious::Command::generate::resources',
    VERSION_FROM => 'lib/Mojolicious/Command/generate/resources.pm', # finds \$VERSION
    AUTHOR       => 'Красимир Беров (berov@cpan.org)',
    ABSTRACT     => 'Generate routes from database for your application',
    PREREQ_PM    => {
                     'Mojolicious' => 7.58,
                    },
);
