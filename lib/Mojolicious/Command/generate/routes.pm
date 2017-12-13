package Mojolicious::Command::generate::routes;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path decamelize);
use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev
  gnu_compat no_ignore_case);
use List::Util qw(first);
File::Spec::Functions->import(qw(catfile catdir splitdir));

our $AUTHORITY = 'cpan:BEROV';
our $VERSION   = '0.01';

has description => 'Generate routes from database for your application';
has usage => sub { shift->extract_usage };


1;

=encoding utf8

=head1 NAME

Mojolicious::Command::generate::routes - Routes from database for your application

=head1 SYNOPSIS

On the command line for one or more tables:

    my_app.pl generate help routes # help with all available options
    my_app.pl generate routes --tables users,groups


=head1 DESCRIPTION


L<Mojolicious::Command::generate::routes> generates directory structure for
a fully functional
L<MVC|http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller>
set of files, based on existing tables in the database. 

This tool's purpose is to promote
L<RAD|http://en.wikipedia.org/wiki/Rapid_application_development> by generating
the boilerplate code for model (M), templates (V) and controller (C) and help
programmers to quickly create well structured, fully functional applications.
It assumes that you already have tables created in a database and you just want
to generate
L<CRUD|https://en.wikipedia.org/wiki/Create,_read,_update_and_delete> actions
for them.

In the generated actions you will find eventually working code for reading,
creating, updating and deleting records from the tables you specified on the
command-line. The generated code is just boilerplate to give you a jump start,
so you can concentrate on writing your business-specific code. It is assumed
that you will modify the generated code to suit your specific needs. All the
generated code is produced from templates which you also can modify to your
taste.

=head1 OPTIONS

Below are the options this command accepts, described in Getopt::Long notation.
Both short and long variants are shown as well as the types of values they
accept. B<MyApp> is used as an example name for your application. All of them,
beside C<--tables>, are guessed from your application and usually do not need
to be specified.


=head2 C|controller_namespace=s

Optional. The namespace for the controller classes to be generated. Defaults to
C<app-E<gt>routes-E<gt>namespaces-E<gt>[0]>, usually L<MyApp::Control>. If you
decide to use another namespace for the controllers, do not forget to add it to
the list C<app-E<gt>routes-E<gt>namespaces> in C<myapp.conf> or your plugin
configuration file. Here is an example.

    # Setting the Controller class from which all controllers must inherit.
    # See /perldoc/Mojolicious/#controller_class
    # See /perldoc/Mojolicious/Guides/Growing#Controller-class
    app->controller_class('MyApp::Control');

    # Namespace(s) to load controllers from
    # See /perldoc/Mojolicious#routes
    app->routes->namespaces(['MyApp::Control']);



=head2 H|home_dir=s

Defaults to C<app<E<gt>home> (which is MyApp home directory). Used to set the
root directory to which the files will be dumped.

=head2 L|lib=s

Defaults to C<$home-E<gt>mojo_lib_dir> relative to the C<--home_dir> directory.
If you installed L<MyApp> in some custom path and you wish to generate your
controllers into e.g. C<site_lib>, set this option.

=head2 M|model_namespace=s

Optional. The namespace for the model classes to be generated. Defaults to
L<MyApp::Model>.

=head2 T|templates_root=s

Defaults to C<app-E<gt>renderer-E<gt>paths-E<gt>[0]>. This is usually
C<templates> directory. If you want to use another directory, do not forget to
add it to the C<app-E<gt>renderer-E<gt>paths> list in your configuration file. Here is how to do it.


    # Application/site specific templates
    # See /perldoc/Mojolicious/Renderer#paths
    unshift @{app->renderer->paths}, $home->rel_file('site_templates');

=head2 t|tables=s@

Mandatory. List of tables separated by commas for which controllers should be generated.


=head1 SUPPORT

Please report bugs, contribute and make merge requests on Github.

=head1 ATTRIBUTES

L<Mojolicious::Command::generate::routes> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $command->description;
  $command        = $command->description('Foo!');

Short description of this command, used for the command list.

=head2 routes

  $self->routes();

Returns an ARRAY reference containing routes, prepared after
C<$self-E<gt>args-E<gt>{tables}>. suggested code for the rutes is dumped on
STDOUT so you can copy and paste into your applicatio code.

=head2 usage

  my $usage = $command->usage;
  $command  = $command->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::generate::routes> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 initialise

  sub run {
      my ($self) = shift->initialise(@_);
      #...
  }

Parses arguments and prepares the command to be run. Calling this method for the second time has no effect.
Returns C<$self>.

=head2 run

  Ado::Command::generate::crud->new(app=>$app)->run(@ARGV);

Run this command.


=head1 AUTHOR

    Красимир Беров
    CPAN ID: BEROV
    berov@cpan.org
    http://i-can.eu

=head1 COPYRIGHT

This program is free software licensed under

	The Artistic License (with Aggregation clause)

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Mojolicious::Command::generate>,
L<Mojolicious::Command>,
L<Mojolicious>,
L<Perl|https://www.perl.org/>.

=cut

