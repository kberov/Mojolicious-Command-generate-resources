# NAME

Mojolicious::Command::generate::resources - Generate M, V & C from database tables

# SYNOPSIS

    Usage: APPLICATION generate resources [OPTIONS]

      my_app.pl generate help resources # help with all available options
      my_app.pl generate resources --tables users,groups

# PERL REQUIREMENTS

This command uses ["signatures" in feature](https://metacpan.org/pod/feature#signatures), therefore Perl 5.20 is required.

# DESCRIPTION

[Mojolicious::Command::generate::resources](https://metacpan.org/pod/Mojolicious::Command::generate::resources) generates directory structure for
a fully functional
[MVC](https://metacpan.org/pod/Mojolicious::Guides::Growing#Model-View-Controller)
[set of files](https://metacpan.org/pod/Mojolicious::Guides::Growing#REpresentational-State-Transfer),
and [routes](https://metacpan.org/pod/Mojolicious::Guides::Routing)
based on existing tables in your application's database. 

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
generated code is produced from templates. You can copy the folder with the
templates, push it to `@{$app->renderer->paths}` and modify to your
taste. Please look into the `t/blog` folder of this distribution for examples.

The command expects to find and will use one of the commonly used helpers
`pg`, `mysql` `sqlite`. The supported wrappers are respectively [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg),
[Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) and [Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite).

# OPTIONS

Below are the options this command accepts, described in Getopt::Long notation.
Both short and long variants are shown as well as the types of values they
accept. All of them, beside `--tables`, are guessed from your application and
usually do not need to be specified.

## C|controller\_namespace=s

Optional. The namespace for the controller classes to be generated. Defaults to
`app->routes->namespaces->[0]`, usually [MyApp::Controller](https://metacpan.org/pod/MyApp::Controller), where
MyApp is the name of your application. If you decide to use another namespace
for the controllers, do not forget to add it to the list
`app->routes->namespaces` in `myapp.conf` or your plugin
configuration file. Here is an example.

    # Setting the Controller class from which all controllers must inherit.
    # See /perldoc/Mojolicious/#controller_class
    # See /perldoc/Mojolicious/Guides/Growing#Controller-class
    app->controller_class('MyApp::C');

    # Namespace(s) to load controllers from
    # See /perldoc/Mojolicious#routes
    app->routes->namespaces(['MyApp::C']);

## H|home\_dir=s

Optional. Defaults to `app->home` (which is MyApp home directory). Used to
set the root directory to which the files will be dumped.

## L|lib=s

Optional. Defaults to `app->home/lib` (relative to the `--home_dir`
directory). If you installed [MyApp](https://metacpan.org/pod/MyApp) in some custom path and you wish to
generate your controllers into e.g. `site_lib`, set this option.

## M|model\_namespace=s

Optional. The namespace for the model classes to be generated. Defaults to
[MyApp::Model](https://metacpan.org/pod/MyApp::Model).

## T|templates\_root=s

Optional. Defaults to `app->renderer->paths->[0]`. This is usually
`app->home/templates` directory. If you want to use another directory, do
not forget to add it to the `app->renderer->paths` list in your
configuration file. Here is how to add a new directory to
`app->renderer->paths` in `myapp.conf`.

    # Application/site specific templates
    # See /perldoc/Mojolicious/Renderer#paths
    unshift @{app->renderer->paths}, $home->rel_file('site_templates');

## t|tables=s@

Mandatory. List of tables separated by commas for which controllers should be generated.

# SUPPORT

Please report bugs, contribute and make merge requests on
[Github](https://github.com/kberov/Mojolicious-Command-generate-resources).

# ATTRIBUTES

[Mojolicious::Command::generate::resources](https://metacpan.org/pod/Mojolicious::Command::generate::resources) inherits all attributes from
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious::Command) and implements the following new ones.

## args

Used for storing arguments from the commandline template.

    my $args = $self->args;

## description

    my $description = $command->description;
    $command        = $command->description('Foo!');

Short description of this command, used for the commands list.

## routes

    $self->routes();

Returns an ARRAY reference containing routes, prepared after
`$self->args->{tables}`. Suggested Perl code for the routes is dumped
in a file named TODO in `--homedir` so you can copy and paste into your
application code.

## usage

    my $usage = $command->usage;
    $command  = $command->usage('Foo!');

Usage information for this command, used for the help screen.

# METHODS

[Mojolicious::Command::generate::resources](https://metacpan.org/pod/Mojolicious::Command::generate::resources) inherits all methods from
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious::Command) and implements the following new ones.

## run

    Mojolicious::Command::generate::resources->new(app=>$app)->run(@ARGV);

Run this command.

## render\_template\_to\_file

Renders a template from a file to a file using [Mojo::Template](https://metacpan.org/pod/Mojo::Template). Parameters:
`$tmpl_file` - full path tho the template file; `$target_file` - full path to
the file to be written; `$template_args` - a hash reference containing the
arguments to the template. See also ["render\_to\_file" in Mojolicious::Command](https://metacpan.org/pod/Mojolicious::Command#render_to_file).

    $self->render_template_to_file($tmpl_file, $target_file, $template_args);

## generate\_formfields

Generates form-fields from columns information found in the repective table.
The result is put into `_form.html.ep`. The programmer can then modify the
generated form-fields.

    $form_fields = $self->generate_formfields($table_name);

## generate\_validation

Generates code for the `_validation` method in the respective controler.

    $validation_code = $self->generate_validation($table_name);

# TODO

The work on the features may not go in the same order specified here. Some
parts may be fully implemented while others may be left for later.

    - Improve documentation.
    - Implement generation of Open API specification out from
      tables' metadata. More tests.

# AUTHOR

    Красимир Беров
    CPAN ID: BEROV
    berov@cpan.org

# COPYRIGHT

This program is free software licensed under

    Artistic License 2.0

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[Mojolicious::Command::generate](https://metacpan.org/pod/Mojolicious::Command::generate),
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious::Command),
[Mojolicious](https://metacpan.org/pod/Mojolicious),
[Perl](https://www.perl.org/).
