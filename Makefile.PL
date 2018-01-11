

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME => 'Mojolicious::Command::generate::resources',
  VERSION_FROM =>
    'lib/Mojolicious/Command/generate/resources.pm',    # finds \$VERSION
  AUTHOR    => 'Красимир Беров (berov@cpan.org)',
  ABSTRACT  => 'Generate resources from database for your application',
  PREREQ_PM => {'Mojolicious' => 7.60,},

  META_MERGE => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime => {requires => {perl => '5.020001'}}},
    resources      => {
      bugtracker => {
        web =>
          'https://github.com/kberov/Mojolicious-Command-generate-resources/issues'
      },
      homepage =>
        'https://github.com/kberov/Mojolicious-Command-generate-resources',
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url =>
          'https://github.com/kberov/Mojolicious-Command-generate-resources.git',
        web =>
          'https://github.com/kberov/Mojolicious-Command-generate-resources',
      },
    },
  },
);
