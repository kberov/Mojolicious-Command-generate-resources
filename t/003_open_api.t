#003_open_api.t
use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Mojo::resources;    # load it from "$FindBin::Bin/lib"

our $tempdir = $Test::Mojo::resources::tempdir
  ;    # tempdir(TMPDIR => 1, TEMPLATE => 'resourcesXXXX');

Test::Mojo::resources::install_app();

require Blog;

# load Open_API into the generated application
my $test = Test::Mojo->new('Blog');
my $blog = $test->app;
{
  my $buffer = '';
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $blog->start('generate', 'resources', '-t' => 'users,groups');

  # If the loaded schema is valid it is by itself a success!!!
  isa_ok(
         $blog->plugin(
                     "OpenAPI" => {url => $blog->home->rel_file("api/api.json")}
         ),
         'Mojolicious::Plugin::OpenAPI'
        );
}
done_testing;

