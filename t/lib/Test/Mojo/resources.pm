package Test::Mojo::resources;

use Mojo::Base -strict;
use Mojo::File qw(path);
use File::Spec::Functions qw(catdir);
use Mojo::Util qw(class_to_path);
use File::Temp qw(tempdir);
use Test::Mojo;
use Test::More;

#our $tempdir = tempdir(TMPDIR => 1, CLEANUP => 1, TEMPLATE => 'resourcesXXXX');

our $tempdir = '/tmp/mres'; # tempdir(TMPDIR => 1, TEMPLATE => 'resourcesXXXX');

# Use the generated application.
unshift @INC, "$tempdir/blog/lib";

require Mojolicious::Commands;

our $commands = Mojolicious::Commands->new;

# Install the app to a temporary path
sub install_app {
  my $MOJO_HOME = "$tempdir/blog";

  # idempotent
  path($MOJO_HOME)->remove_tree->make_path({mode => 0700});
  for (path('t/blog')->list_tree({dir => 1})->each) {
    my $new_path = $_->to_array;
    splice @$new_path, 0, 2;    #t/blog/blog.conf -> blog.conf
    unshift @$new_path, $MOJO_HOME;    #blog.conf -> $ENV{MOJO_HOME}/blog.conf
    path(catdir(@$new_path))->make_path({mode => 0700}) if -d $_;
    $_->copy_to(catdir(@$new_path)) if -f $_;
  }
  return;
}
1;
