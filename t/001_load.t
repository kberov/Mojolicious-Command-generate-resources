# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;

BEGIN { use_ok('Mojolicious::Command::generate::resources'); }


