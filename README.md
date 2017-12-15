# NAME

Mojolicious::Command::generate::resources - Resources from database for your application

# SYNOPSIS

On the command line for one or more tables:

    my_app.pl generate help resources # help with all available options
    my_app.pl generate resources --tables users,groups

# DESCRIPTION

[Mojolicious::Command::generate::resources](https://metacpan.org/pod/Mojolicious::Command::generate::resources) generates directory structure for
a fully functional
[MVC](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller)
set of files, based on existing tables in the database. 

This tool's purpose is to promote
[RAD](http://en.wikipedia.org/wiki/Rapid_application_development) by generating
the boilerplate code for model (M), templates (V) and controller (C) and help
programmers to quickly create well structured, fully functional applications.
It assumes that you already have tables created in a database and you just want
to generate
[CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) actions
for them.

In the generated actions you will find eventually working code for reading,
creating, updating and deleting records from the tables you specified on the
command-line. The generated code is just boilerplate to give you a jump start,
so you can concentrate on writing your business-specific code. It is assumed
that you will modify the generated code to suit your specific needs. All the
generated code is produced from templates which you also can modify to your
taste.

# OPTIONS

Below are the options this command accepts, described in Getopt::Long notation.
Both short and long variants are shown as well as the types of values they
accept. **MyApp** is used as an example name for your application. All of them,
beside `--tables`, are guessed from your application and usually do not need
to be specified.

## C|controller\_namespace=s

Optional. The namespace for the controller classes to be generated. Defaults to
`app->routes->namespaces->[0]`, usually [MyApp::Controller](https://metacpan.org/pod/MyApp::Controller). If you
decide to use another namespace for the controllers, do not forget to add it to
the list `app->routes->namespaces` in `myapp.conf` or your plugin
configuration file. Here is an example.

    # Setting the Controller class from which all controllers must inherit.
    # See /perldoc/Mojolicious/#controller_class
    # See /perldoc/Mojolicious/Guides/Growing#Controller-class
    app->controller_class('MyApp::Control');

    # Namespace(s) to load controllers from
    # See /perldoc/Mojolicious#routes
    app->routes->namespaces(['MyApp::Control']);

## H|home\_dir=s

Defaults to `app->home` (which is MyApp home directory). Used to set the
root directory to which the files will be dumped.

## L|lib=s

Defaults to `$home->mojo_lib_dir` relative to the `--home_dir` directory.
If you installed [MyApp](https://metacpan.org/pod/MyApp) in some custom path and you wish to generate your
controllers into e.g. `site_lib`, set this option.

## M|model\_namespace=s

Optional. The namespace for the model classes to be generated. Defaults to
[MyApp::Model](https://metacpan.org/pod/MyApp::Model).

## T|templates\_root=s

Defaults to `app->renderer->paths->[0]`. This is usually
`templates` directory. If you want to use another directory, do not forget to
add it to the `app->renderer->paths` list in your configuration file.
Here is how to add a new directory to `app->renderer->paths`.

    # Application/site specific templates
    # See /perldoc/Mojolicious/Renderer#paths
    unshift @{app->renderer->paths}, $home->rel_file('site_templates');

## t|tables=s@

Mandatory. List of tables separated by commas for which controllers should be generated.

# SUPPORT

Please report bugs, contribute and make merge requests on Github.

# ATTRIBUTES

[Mojolicious::Command::generate::routes](https://metacpan.org/pod/Mojolicious::Command::generate::routes) inherits all attributes from
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious::Command) and implements the following new ones.

## args

Used for storing arguments from the commandline and then passing them to the
template

    my $args = $self->args;

## description

    my $description = $command->description;
    $command        = $command->description('Foo!');

Short description of this command, used for the command list.

## routes

    $self->routes();

Returns an ARRAY reference containing routes, prepared after
`$self->args->{tables}`. suggested code for the rutes is dumped on
STDOUT so you can copy and paste into your application code.

## usage

    my $usage = $command->usage;
    $command  = $command->usage('Foo!');

Usage information for this command, used for the help screen.

# METHODS

[Mojolicious::Command::generate::resources](https://metacpan.org/pod/Mojolicious::Command::generate::resources) inherits all methods from
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious::Command) and implements the following new ones.

## run

    Ado::Command::generate::crud->new(app=>$app)->run(@ARGV);

Run this command.

# TODO

Please take a look at the file TODO in the root folder of this distribution.

# AUTHOR

    Красимир Беров
    CPAN ID: BEROV
    berov@cpan.org
    http://i-can.eu

# COPYRIGHT

This program is free software licensed under

        The Artistic License (with Aggregation clause)

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[Mojolicious::Command::generate](https://metacpan.org/pod/Mojolicious::Command::generate),
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious::Command),
[Mojolicious](https://metacpan.org/pod/Mojolicious),
[Perl](https://www.perl.org/).
