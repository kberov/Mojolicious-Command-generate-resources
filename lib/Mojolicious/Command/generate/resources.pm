package Mojolicious::Command::generate::resources;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path decamelize camelize);
use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev
  gnu_compat no_ignore_case);
use List::Util qw(first);
File::Spec::Functions->import(qw(catfile catdir splitdir));

our $AUTHORITY = 'cpan:BEROV';
our $VERSION   = '0.02';

has args => sub { {} };
has description =>
  'Generate resources from database tables for your application';
has usage => sub { shift->extract_usage };


has routes => sub {
  $_[0]->{routes} = [];
  foreach my $t (@{$_[0]->args->{tables}}) {
    my $controller = camelize($t);
    my $route      = decamelize($controller);
    push @{$_[0]->{routes}},
      {route => "/$route",      via => ['GET'], to => "$route#list",},
      {route => "/$route/list", via => ['GET'], to => "$route#list",},
      {route => "/$route/read/:id", via => [qw(GET)], to => "$route#read",},
      {
       route => "/$route/create",
       via   => [qw(GET POST)],
       to    => "$route#create",
       over  => {authenticated => 1},
      },
      {
       route => "/$route/update/:id",
       via   => [qw(GET PUT)],
       to    => "$route#update",
       over  => {authenticated => 1},
      },
      {
       route => "/$route/delete/:id",
       via   => [qw(GET DELETE)],
       to    => "$route#delete",
       over  => {authenticated => 1},
      };
  }
  return $_[0]->{routes};
};

my $_начевамъ = sub {
  my ($азъ, @args) = @_;
  return $азъ if $азъ->{_initialised};
  my $args = $азъ->args({tables => []})->args;

  GetOptionsFromArray(
                   \@args,
                   'C|controller_namespace=s' => \$args->{controller_namespace},
                   'L|lib=s'                  => \$args->{lib},
                   'M|model_namespace=s'      => \$args->{model_namespace},
                   'O|overwrite'              => \$args->{overwrite},
                   'T|templates_root=s'       => \$args->{templates_root},
                   't|tables=s@'              => \$args->{tables},
                   'H|home_dir=s'             => \$args->{home_dir},
  );

  @{$args->{tables}} = split(/s*?\,\s*?/, join(',', @{$args->{tables}}));
  Carp::croak $азъ->usage unless scalar @{$args->{tables}};

  my $app = $азъ->app;
  $args->{controller_namespace} //= $app->routes->namespaces->[0];
  $args->{model_namespace}      //= [ref($app) . '::Model'];
  $args->{home_dir}             //= $app->home;
  $args->{lib}                  //= catdir($args->{home_dir}, 'lib');
  $args->{templates_root}       //= $app->renderer->paths->[0];
  $азъ->{_initialised} = 1;

  return $азъ;
};


sub run {
  my ($self) = shift->$_начевамъ(@_);
  my $args   = $self->args;
  my $app    = $self->app;

  foreach my $t (@{$args->{tables}}) {

    # Controllers
    my $class_name = camelize($t);
    $args->{class} = $args->{controller_namespace} . '::' . $class_name;
    my $c_file = catfile($args->{lib}, class_to_path($args->{class}));
    $args->{t} = lc $t;
    $self->render_to_file('class', $c_file, $args);

    # Templates
    my $template_dir  = decamelize($class_name);
    my $template_root = $args->{templates_root};
    my $t_file        = catfile($template_root, $template_dir, 'list.html.ep');
    $self->render_to_file('list_template', $t_file, $args);
    $t_file = catfile($template_root, $template_dir, 'create.html.ep');
    $self->render_to_file('create_template', $t_file, $args);
    $t_file = catfile($template_root, $template_dir, 'read.html.ep');
    $self->render_to_file('read_template', $t_file, $args);
    $t_file = catfile($template_root, $template_dir, 'delete.html.ep');
    $self->render_to_file('delete_template', $t_file, $args);
  }    # end foreach tables

  return $self;
}


1;

=encoding utf8

=head1 NAME

Mojolicious::Command::generate::resources - Resources from database for your application

=head1 SYNOPSIS

On the command line for one or more tables:

    my_app.pl generate help resources # help with all available options
    my_app.pl generate resources --tables users,groups


=head1 DESCRIPTION


L<Mojolicious::Command::generate::resources> generates directory structure for
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
C<app-E<gt>routes-E<gt>namespaces-E<gt>[0]>, usually L<MyApp::Controller>. If you
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

Defaults to C<app-E<gt>home> (which is MyApp home directory). Used to set the
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
add it to the C<app-E<gt>renderer-E<gt>paths> list in your configuration file.
Here is how to add a new directory to C<app-E<gt>renderer-E<gt>paths>.


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

=head2 args

Used for storing arguments from the commandline and then passing them to the
template

  my $args = $self->args;

=head2 description

  my $description = $command->description;
  $command        = $command->description('Foo!');

Short description of this command, used for the command list.

=head2 routes

  $self->routes();

Returns an ARRAY reference containing routes, prepared after
C<$self-E<gt>args-E<gt>{tables}>. suggested code for the rutes is dumped on
STDOUT so you can copy and paste into your application code.

=head2 usage

  my $usage = $command->usage;
  $command  = $command->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::generate::resources> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  Ado::Command::generate::crud->new(app=>$app)->run(@ARGV);

Run this command.

=head1 TODO

Please take a look at the file TODO in the root folder of this distribution.

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


__DATA__

@@ class
% my $a = shift;
package <%= $a->{class} %>;
use Mojo::Base '<%= $a->{controller_namespace} %>';

our $VERSION = '0.01';


# List resourses from table <%= $a->{t} %>.
sub list {
    my $c = shift;
    # 1. Get a range of rows from the database.
    my $list = [
        {id=>1, title=>'hello', body =>'the whole text for "hello"'},
        {id=>2, title=>'world', body =>'the whole text for "world"'},
    ];
    # 2. Return it to the user.
    return $c->respond_to(
        json => $list,
        html =>{list =>$list}
    );
}

# Creates a resource in table <%= $a->{t} %>.
sub create {
    my $c = shift;
    my $v = $c->validation;
    return $c->render unless $v->has_data;

    $v->required('title')->size(3, 50);
    $v->required('body')->size(3, 1 * 1024 * 1024);#1MB
    # 1. Validate the input
    # 2. Insert it into the databse
    # 3. Prepare the response data or just return "201 Created"
    # See https://developer.mozilla.org/docs/Web/HTTP/Status/201
    my $data = {id => 1, 
        title => 'Hello World', body =>'the text of the "Hello World" article'};

    return $c->respond_to(
        json => {data => $data},
        html => {data => $data}
    );
}

# Reads a resource from table <%= $a->{t} %>.
sub read {
    my $c = shift;
    # This could be validated by a stricter route placeholder.
    my ($id) = $c->stash('id') =~/(\d+)/;
    
    # 1. Find the data in table $a->{t}.
    my $data = {id => $id , 
        title => 'Hello World', body =>'the text of the "Hello World" article'};
    $c->debug('$data:'.$c->dumper($data));

    # 2. Return it to the user.
    return $c->respond_to(
        json => {$a->{t} => $data},
        html => {$a->{t} => $data}
    );
}

# Updates a resource in table <%= $a->{t} %>.
sub update {
    my $c = shift;
    my $v = $c->validation;
    my ($id) = $c->stash('id') =~/(\d+)/;
    
    # 1. Find the data in table $a->{t}.
    my $data = {id => $id , 
        title => 'Hello World', body =>'the text of the "Hello World" article'};
    $c->reply->not_found() unless $data;
    $c->debug('$data:'.$c->dumper($res->data));

    # 2., 3. Validate and update the data.
    if($v->has_data && $data){
        $v->optional('title')->size(3, 50);
        $v->optional('body')->size(3, 1 * 1024 * 1024);#1MB
        # $res->title($v->param('title'))->body($v->param('body'))
        #   ->update() unless $v->has_error;
    }

    # 4. Return the updated the data or just send "204 No Content"
    # See https://developer.mozilla.org/bg/docs/Web/HTTP/Status/204
    return $c->respond_to(
        json => {article => $data},
        html => {article => $data}
    );
}

# "Deletes" a resource from table <%= $a->{t} %>.
sub delete {
    return shift->render(message => '"delete" is not implemented...');
}



1;

<% %>__END__

<% %>=encoding utf8

<% %>=head1 NAME

<%= $a->{class} %> - a controller for resource <%= $a->{t} %>.

<% %>=head1 SYNOPSIS



<% %>=cut



@@ list_template
% $a = shift;
%% my $columns = [qw(id title body)];
<table>
  <thead>
    <tr>
    %% foreach my $column( @$columns ){
      <th><%%= $column %></th>
    %% }
    </tr>
  </thead>
  <tbody>
    %% foreach my $row (@{$list->{json}{data}}) {
    <tr>
      %% foreach my $column( @$columns ){
      <td><%%= $row->{$column} %></td>
      %% }
    </tr>
    %% }
  </tbody>
    %%#== $c->dumper($list);
</table>

@@ create_template
% $a = shift;
<article>
  Create your form for creating a resource here.
</article>

@@ read_template
% $a = shift;
<article id="<%%= $article->{id} %>">
  <h1><%%= $article->{title} %></h1>
  <section><%%= $article->{body} %></section>
</article>

@@ update_template
% $a = shift;
<article>
  Create your form for updating a resource here.
</article>


@@ delete_template
% $a = shift;
<article>
  <section class="ui error form segment"><%%= $message %></section>
</article>


