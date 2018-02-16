#003_open_api.t
use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Mojo::resources;    # load it from "$FindBin::Bin/lib"

our $tempdir = Test::Mojo::resources::tempdir;

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

  like($buffer, qr{\[write\].+?api[\\/]api.json}, "written api/api.json");
}

# If the loaded schema is valid, it is by itself a success!!!
ok($blog->plugin("OpenAPI" => {url => $blog->home->rel_file("api/api.json")}),
   'loaded Mojolicious::Plugin::OpenAPI');

done_testing;

