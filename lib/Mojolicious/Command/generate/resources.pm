package Mojolicious::Command::generate::resources;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::Util qw(class_to_path decamelize camelize);
use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev
  gnu_compat no_ignore_case);
File::Spec::Functions->import(qw(catfile catdir));
use Mojo::File 'path';

our $AUTHORITY = 'cpan:BEROV';
our $VERSION   = '0.11';

has args => sub { {} };
has description => sub {
  if ($_[1]) {
    $_[0]->{description} = $_[1];
    return $_[0];
  }
  return $_[0]->{description} if $_[0]->{description};
  state $bytes   = path(__FILE__)->slurp();
  state $package = __PACKAGE__;
  return $_[0]->{description} = ($bytes =~ /$package\s+-\s+(.+)\n/)[0];
};

has usage => sub { shift->extract_usage };
has _templates_path => '';
has '_db_helper';

has routes => sub {
  $_[0]->{routes} = [];
  foreach my $t (@{$_[0]->args->{tables}}) {
    my $controller = camelize($t);
    my $route      = decamelize($controller);
    push @{$_[0]->{routes}},
      {
       route => "/$route",
       via   => ['GET'],
       to    => "$route#index",
       name  => "home_$route"
      },
      {
       route => "/$route/create",
       via   => ['GET'],
       to    => "$route#create",
       name  => "create_$route",
      },
      {
       route => "/$route/:id",
       via   => ['GET'],
       to    => "$route#show",
       name  => "show_$route"
      },
      {
       route => "/$route",
       via   => ['POST'],
       to    => "$route#store",
       name  => "store_$route",
      },
      {
       route => "/$route/:id/edit",
       via   => ['GET'],
       to    => "$route#edit",
       name  => "edit_$route"
      },
      {
       route => "/$route/:id",
       via   => ['PUT'],
       to    => "$route#update",
       name  => "update_$route"
      },
      {
       route => "/$route/:id",
       via   => ['DELETE'],
       to    => "$route#remove",
       name  => "remove_$route"
      };
  }
  return $_[0]->{routes};
};

my $_init = sub ($self, @options) {
  return $self if $self->{_initialised};

  # Make sure the "tables" argument exists as an empty array
  my $args = $self->args({tables => []})->args;

  GetOptionsFromArray(
    \@options,
    'H|home_dir=s'             => \$args->{home_dir},
    'L|lib=s'                  => \$args->{lib},
    'A|api_dir'                => \$args->{api_dir},
    'C|controller_namespace=s' => \$args->{controller_namespace},
    'M|model_namespace=s'      => \$args->{model_namespace},

    # TODO: 'O|overwrite'              => \$args->{overwrite},
    'T|templates_root=s' => \$args->{templates_root},
    't|tables=s@'        => \$args->{tables},
                     );

  @{$args->{tables}} = split(/\s*?\,\s*?/, join(',', @{$args->{tables}}));
  Carp::croak $self->usage unless scalar @{$args->{tables}};

  my $app = $self->app;
  $args->{controller_namespace} //= $app->routes->namespaces->[0];
  $args->{model_namespace}      //= ref($app) . '::Model';
  $args->{home_dir}             //= $app->home;
  $args->{lib}                  //= catdir($args->{home_dir}, 'lib');
  $args->{api_dir}              //= catdir($args->{home_dir}, 'api');
  $args->{templates_root}       //= $app->renderer->paths->[0];

  # Find templates.
  # TODO: Look into renderer->paths for user-defined/modified templates
  for my $path (@INC) {
    my $templates_path
      = catdir($path, 'Mojolicious/resources/templates/mojo/command/resources');
    if (-d $templates_path) {
      $self->_templates_path($templates_path);
      last;
    }
  }

  # Find the used database helper. One of sqlite, pg, mysql
  my @db_helpers = qw(sqlite pg mysql);
  for (@db_helpers) {
    if ($app->renderer->get_helper($_)) {
      $self->_db_helper($_);
      last;
    }
  }
  if (!$self->_db_helper) {
    die <<'MSG';
Guessing the used database wrapper helper failed. One of (@db_helpers) is
required. This application does not use any of the supported database helpers.
One of Mojo::Pg, Mojo::mysql or Mojo::SQLite must be used to generate models.
Aborting!..
MSG
  }

  $self->{_initialised} = 1;

  return $self;
};

# Returns the full path to the first found template.
# See http://localhost:3000/perldoc/Mojolicious/Renderer#template_path
sub _template_path ($self, $template) {
  state $paths      = $self->app->renderer->paths;
  state $tmpls_path = $self->_templates_path;
  -r and return $_ for map { catfile($_, $template) } @$paths, $tmpls_path;
  return;
}

sub run ($self, %options) {
  $self->$_init(%options);
  my $args = $self->args;
  my $app  = $self->app;

  my $wrapper_helpers = '';
  for my $t (@{$args->{tables}}) {

    my $class_name = camelize($t);

    # Models
    my $mclass        = "$args->{model_namespace}::$class_name";
    my $m_file        = catfile($args->{lib}, class_to_path($mclass));
    my $table_columns = $self->_get_table_columns($t);
    my $template_args = {
                         %$args,
                         class       => $mclass,
                         t           => lc $t,
                         db_helper   => $self->_db_helper,
                         columns     => $table_columns,
                         column_info => $self->_column_info($t),
                        };
    my $tmpl_file = $self->_template_path('m_class.ep');
    $self->render_template_to_file($tmpl_file, $m_file, $template_args);

    # Controllers
    my $class = "$args->{controller_namespace}::$class_name";
    my $c_file = catfile($args->{lib}, class_to_path($class));
    $template_args = {
                      %$template_args,
                      class      => $class,
                      validation => $self->generate_validation($t)
                     };
    $tmpl_file = $self->_template_path('c_class.ep');
    $self->render_template_to_file($tmpl_file, $c_file, $template_args);


    # Templates
    my $template_dir  = decamelize($class_name);
    my $template_root = $args->{templates_root};

    my @views = qw(index create show edit);
    for my $v (@views) {
      my $to_t_file = catfile($template_root, $template_dir, $v . '.html.ep');
      my $tmpl = $self->_template_path($v . '.html.ep');
      $self->render_template_to_file($tmpl, $to_t_file, $template_args);
    }
    $tmpl_file = $self->_template_path('_form.html.ep');
    my $to_t_file = catfile($template_root, $template_dir, '_form.html.ep');
    $template_args
      = {%$template_args, fields => $self->generate_formfields($t)};
    $self->render_template_to_file($tmpl_file, $to_t_file, $template_args);

    # Helpers
    $template_args = {%$template_args, class => $mclass};
    $tmpl_file = $self->_template_path('helper.ep');
    $wrapper_helpers
      .= Mojo::Template->new->render_file($tmpl_file, $template_args);
  }    # end foreach tables

  #OpenAPI
  $self->generate_openapi();

  # Routes
  my $template_args
    = {%$args, helpers => $wrapper_helpers, routes => $self->routes};
  my $tmpl_file = $self->_template_path('TODO.ep');
  my $todo_file = catfile($args->{home_dir}, 'TODO');
  $self->render_template_to_file($tmpl_file, $todo_file, $template_args);
  return $self;
}

# Returns an array reference of columns from the table
sub _get_table_columns ($self, $table) {
  my @columns = map ({ $_->{COLUMN_NAME} } @{$self->_column_info($table)});
  return \@columns;
}

sub _column_info ($self, $table) {
  state $tci       = {};                  #tables column info
  state $db_helper = $self->_db_helper;
  $tci->{$table}
    //= $self->app->$db_helper->db->dbh->column_info(undef, undef, $table, '%')
    ->fetchall_arrayref({});
  return $tci->{$table};
}

sub render_template_to_file ($self, $filename, $path, $args) {
  my $out = Mojo::Template->new->render_file($filename, $args);
  return $self->write_file($path, $out);
}

sub generate_formfields ($self, $table) {
  my $fields = '';
  for my $col (@{$self->_column_info($table)}) {
    my $name     = $col->{COLUMN_NAME};
    my $required = $col->{NULLABLE} ? '' : 'required => 1,';
    my $size     = $col->{COLUMN_SIZE} ? "size => $col->{COLUMN_SIZE}" : '';
    if ($name eq 'id') {
      $fields
        .= qq|\n%=hidden_field '$name' => \$${table}->{id} if (\$action ne 'create');\n|;
      next;
    }
    if ($col->{TYPE_NAME} =~ /char/i && $col->{COLUMN_SIZE} < 256) {
      $fields .= <<"QQ";
  %= label_for $name =>'${\ucfirst($name)}'\n<br />
  %= text_field $name => \$${table}->{$name}, $required $size\n<br />
QQ
      next;
    }
    elsif (   $col->{TYPE_NAME} =~ /text/i
           || $col->{TYPE_NAME} =~ /char/i && $col->{COLUMN_SIZE} > 255)
    {
      $fields .= <<"QQ";
  %= label_for '$name' => '${\ucfirst($name)}'\n<br />
  %= text_area '$name' => \$${table}->{$name}, $required $size\n<br />
QQ
      next;
    }
    if ($col->{TYPE_NAME} =~ /INT|FLOAT|DOUBLE|DECIMAL/i) {
      $fields .= <<"QQ";
  %= label_for $name => '${\ucfirst($name)}'\n<br />
  %= number_field $name => \$${table}->{$name}, $required $size\n<br />
QQ
      next;
    }
  }
  return $fields;
}

sub generate_validation ($self, $table) {
  my $fields = '';
  for my $col (@{$self->_column_info($table)}) {
    my $name     = $col->{COLUMN_NAME};
    my $required = $col->{NULLABLE} ? 0 : 1;
    my $size     = $col->{COLUMN_SIZE} ? "size => $col->{COLUMN_SIZE}" : '';
    if ($name eq 'id') {
      $fields .= qq|\$v->required('id') if \$c->stash->{action} ne 'store';\n|;
      next;
    }

    $fields
      .= $required
      ? qq|\$v->required('$name', 'trim')|
      : qq|\$v->optional('$name', 'trim')|;
    if ($col->{TYPE_NAME} =~ /char/i && $col->{COLUMN_SIZE} < 256) {
      $fields .= "->size(0, $col->{COLUMN_SIZE})";
    }

    if ($col->{TYPE_NAME} =~ /INT|FLOAT|DOUBLE|DECIMAL/i) {
      $fields .= q|->like(qr/\d+(\.\d+)?/)|;
    }
    $fields .= ';' . $/;
  }
  return $fields;
}

sub generate_openapi ($self) {
  my $tmpl_args      = {%{$self->args}};
  my $api_dir        = $tmpl_args->{api_dir};
  my $api_tmpl_file  = $self->_template_path('api.json.ep');
  my $api_file       = catfile($api_dir, 'api.json');
  my $defs_tmpl_file = $self->_template_path('definitions.json.ep');
  my $defs_file      = catfile($api_dir, 'definitions.json');
  $tmpl_args->{api_title}  = ref($self->app);
  $tmpl_args->{api_paths}  = {};
  $tmpl_args->{api_params} = {};
  my $api_defs = {};
  $tmpl_args->{api_definitions} = $api_defs;

  for my $t (@{$tmpl_args->{tables}}) {

    # Generate descriptions for table objects.
    my $class_name = $tmpl_args->{class_name} = camelize($t);
    my $object_name = $class_name . 'Item';
    $api_defs->{$class_name}{items}{'$ref'} = "/resources/$object_name";
    $api_defs->{$class_name}{type} = 'array';
    $api_defs->{$object_name}{description}
      = "An object, representing one item of $class_name.";

    # Generate definition and parameter description for each column.
    $self->generate_columns_api($t, $api_defs->{$object_name}, $tmpl_args);
  }

  # $self->app->log->debug($self->app->dumper($api_defs));
  $self->render_template_to_file($defs_tmpl_file, $defs_file, $tmpl_args);
  $self->render_template_to_file($api_tmpl_file,  $api_file,  $tmpl_args);

 # Prettify generated JSON.
 # With this step we also make sure the generated JSON is syntactically correct.
  my $ugly = path($defs_file)->slurp();
  path($defs_file)
    ->spurt(JSON::PP->new->utf8->pretty->encode(JSON::PP::decode_json($ugly)));

  $ugly = path($api_file)->slurp();
  path($api_file)
    ->spurt(JSON::PP->new->utf8->pretty->encode(JSON::PP::decode_json($ugly)));

  return;
}

sub generate_columns_api ($self, $t, $object_api_def, $tmpl_args) {
  $object_api_def->{properties} = {};
  $object_api_def->{required}   = [];
  for my $col (@{$self->_column_info($t)}) {
    my $name       = $col->{COLUMN_NAME};
    my $size       = $col->{COLUMN_SIZE} || 0;
    my $type       = $col->{TYPE_NAME};
    my $param_name = camelize($name) . "Of$tmpl_args->{class_name}";
    $tmpl_args->{api_params}{$param_name} = {name => $name};

    unless ($col->{NULLABLE}) {
      $tmpl_args->{api_params}{$param_name}{required} = Mojo::JSON->true;
      push @{$object_api_def->{required}}, $name;
    }

    if ($type =~ /char|text|clob/i) {
      $object_api_def->{properties}{$name}
        = {($size ? (maxLength => $size) : ()), type => 'string'};
      $tmpl_args->{api_params}{$param_name}{maxLength} = $size if $size;
      $tmpl_args->{api_params}{$param_name}{type} = 'string';
    }
    elsif ($type =~ /INT/i) {
      $object_api_def->{properties}{$name}
        = {($size ? (maxLength => $size) : ()), type => 'integer'};
      $tmpl_args->{api_params}{$param_name}{maxLength} = $size if $size;
      $tmpl_args->{api_params}{$param_name}{type} = 'integer';
    }
    elsif ($type =~ /FLOAT|DOUBLE|DECIMAL|NUMBER/i) {
      my $scale     = $col->{DECIMAL_DIGITS} || 0;
      my $precision = $size - $scale;
      my $pattern   = qr/^-?\d{1,$precision}(?:\.\d{0,$scale})?$/x;
      $object_api_def->{properties}{$name} = {
                                            ($size ? (maxLength => $size) : ()),
                                            type    => 'number',
                                            pattern => $pattern
      };
      $tmpl_args->{api_params}{$param_name}{maxLength} = $size if $size;
      $tmpl_args->{api_params}{$param_name}{type} = 'number';
    }

    #/$t/id
    if ($name eq 'id') {
      my $id_in_path_param = {
                              %{$tmpl_args->{api_params}{$param_name} || {}},
                              in       => 'path',
                              required => Mojo::JSON->true
                             };

      # GET and DELETE
      push @{$tmpl_args->{show_params}}, $id_in_path_param;

      # PUT
      push @{$tmpl_args->{update_params}}, $id_in_path_param;

      next;
    }

    # POST
    push @{$tmpl_args->{store_params}},
      {'$ref' => "definitions.json#/api_params/$param_name"};

    # PUT
    push @{$tmpl_args->{update_params}},
      {'$ref' => "definitions.json#/api_params/$param_name"};

  }    #end for my $col (@{$self->_column_info($t)})

  $tmpl_args->{t} = lc $t;

  state $path_tmpl_file = $self->_template_path('path.json.ep');
  my $path_file = catfile($tmpl_args->{api_dir}, "$t.json");
  $self->render_template_to_file($path_tmpl_file, $path_file, $tmpl_args);
  $tmpl_args->{api_paths}{"/$t"}      = {'$ref' => "$t.json#/~1$t"};
  $tmpl_args->{api_paths}{"/$t/{id}"} = {'$ref' => "$t.json#/~1$t~1{id}"};

 # prettify generated JSON.
 # With this step we also make sure the generated JSON is syntactically correct.
  my $ugly = path($path_file)->slurp();
  path($path_file)
    ->spurt(JSON::PP->new->utf8->pretty->encode(JSON::PP::decode_json($ugly)));

  # Cleanup for the next table
  delete $tmpl_args->{$_} for (qw(t store_params update_params show_params));
  return;
}

1;


=encoding utf8

=head1 NAME

Mojolicious::Command::generate::resources - Generate MVC & OpenAPI RESTful API files from database tables

=head1 SYNOPSIS

  Usage: APPLICATION generate resources [OPTIONS]

    my_app.pl generate help resources # help with all available options
    my_app.pl generate resources --tables users,groups

=head1 PERL REQUIREMENTS

This command uses L<feature/signatures>, therefore Perl 5.20 is required.

=head1 DESCRIPTION

An early release...

L<Mojolicious::Command::generate::resources> generates directory structure for
a fully functional L<MVC|Mojolicious::Guides::Growing/"Model View Controller">
L<set of files|Mojolicious::Guides::Growing/"REpresentational State Transfer">,
L<routes|Mojolicious::Guides::Routing> and RESTful API specification in
L<OpenAPI|https://github.com/OAI/OpenAPI-Specification> format based on
existing tables in your application's database. 

The purpose of this tool is to promote
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
generated code is produced from templates. You can copy the folder with the
templates, push it to C<@{$app-E<gt>renderer-E<gt>paths}> and modify to your
taste. Please look into the C<t/blog> folder of this distribution for examples.

The command expects to find and will use one of the commonly used helpers
C<pg>, C<mysql> C<sqlite>. The supported wrappers are respectively L<Mojo::Pg>,
L<Mojo::mysql> and L<Mojo::SQLite>.

=head1 OPTIONS

Below are the options this command accepts, described in Getopt::Long notation.
Both short and long variants are shown as well as the types of values they
accept. All of them, beside C<--tables>, are guessed from your application and
usually do not need to be specified.


=head2 H|home_dir=s

Optional. Defaults to C<app-E<gt>home> (which is MyApp home directory). Used to
set the root directory to which the files will be dumped. If you set this
option, respectively the C<lib> and C<api> folders will be created under the
new C<home_dir>. If you want them elsewhere, set these options explicitly.

=head2 L|lib=s

Optional. Defaults to C<app-E<gt>home/lib> (relative to the C<--home_dir>
directory). If you installed L<MyApp> in some custom path and you wish to
generate your controllers into e.g. C<site_lib>, set this option.

=head2 api_dir

Optional. Directory where
the L<OpenAPI|https://github.com/OAI/OpenAPI-Specification> C<json> files will
be generated. Defaults to C<app-E<gt>home/api> (relative to the C<--home_dir>
directory). If you installed L<MyApp> in some custom path and you wish to
generate your C<OpenApi> files into for example C<site_lib/MyApp/etc/api>, set
this option explicitly.

=head2 C|controller_namespace=s

Optional. The namespace for the controller classes to be generated. Defaults to
C<app-E<gt>routes-E<gt>namespaces-E<gt>[0]>, usually L<MyApp::Controller>, where
MyApp is the name of your application. If you decide to use another namespace
for the controllers, do not forget to add it to the list
C<app-E<gt>routes-E<gt>namespaces> in C<myapp.conf> or your plugin
configuration file. Here is an example.

  # Setting the Controller class from which all controllers must inherit.
  # See /perldoc/Mojolicious/#controller_class
  # See /perldoc/Mojolicious/Guides/Growing#Controller-class
  app->controller_class('MyApp::C');

  # Namespace(s) to load controllers from
  # See /perldoc/Mojolicious#routes
  app->routes->namespaces(['MyApp::C']);

=head2 M|model_namespace=s

Optional. The namespace for the model classes to be generated. Defaults to
L<MyApp::Model>.

=head2 T|templates_root=s

Optional. Defaults to C<app-E<gt>renderer-E<gt>paths-E<gt>[0]>. This is usually
C<app-E<gt>home/templates> directory. If you want to use another directory, do
not forget to add it to the C<app-E<gt>renderer-E<gt>paths> list in your
configuration file. Here is how to add a new directory to
C<app-E<gt>renderer-E<gt>paths> in C<myapp.conf>.

    # Application/site specific templates
    # See /perldoc/Mojolicious/Renderer#paths
    unshift @{app->renderer->paths}, $home->rel_file('site_templates');

=head2 t|tables=s@

Mandatory. List of tables separated by commas for which controllers should be generated.

=head1 SUPPORT

Please report bugs, contribute and make merge requests on
L<Github|https://github.com/kberov/Mojolicious-Command-generate-resources>.

=head1 ATTRIBUTES

L<Mojolicious::Command::generate::resources> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 args

Used for storing arguments from the command-line.

  my $args = $self->args;

=head2 description

  my $description = $command->description;
  $command        = $command->description('Foo!');

Short description of this command, used for the C<~$ mojo generate> commands
list.

=head2 routes

  $self->routes;

Returns an ARRAY reference containing routes, prepared after
C<$self-E<gt>args-E<gt>{tables}>. Suggested Perl code for the routes is dumped
in a file named TODO in C<--homedir> so you can copy and paste into your
application code.

=head2 usage

  my $usage = $command->usage;
  $command  = $command->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::generate::resources> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  Mojolicious::Command::generate::resources->new(app=>$app)->run(@ARGV);

Run this command.

=head2 render_template_to_file

Renders a template from a file to a file using L<Mojo::Template>. Parameters:
C<$tmpl_file> - full path tho the template file; C<$target_file> - full path to
the file to be written; C<$template_args> - a hash reference containing the
arguments to the template. See also L<Mojolicious::Command/render_to_file>.

    $self->render_template_to_file($tmpl_file, $target_file, $template_args);

=head2 generate_formfields

Generates form-fields from columns information found in the respective table.
The result is put into C<_form.html.ep>. The programmer can then modify the
generated form-fields.

    $form_fields = $self->generate_formfields($table_name);

=head2 generate_openapi

Generates L<Open API|https://github.com/OAI/OpenAPI-Specification> files in
json format.  The generated files are put in L</--api_dir>. The files are:
C<api.json> - the file which will be loaded by C<MyApp> and refers to the
specific path files; C<definitions.json> - this file is referred to in the
specific path files; C<$path.json> - a file for each resource, based on the
table name from which it is generated.

=head2 generate_path_api

Generates API definitions and path file for each table. Invoked in
L</generate_openapi>. B<Paramaters:> C<$t> - the table name;
$C<$api_defs_object> - the object API definition, based on the table name;
C<$tmpl_args> - the arguments for the templates. C<$api_defs_object> and
$C<tmpl_args> will be enriched with additional key-value pairs as required by
the OpenAPI specification. Returns C<void>.

=head2 generate_validation

Generates code for the C<_validation> method in the respective controler.

    $validation_code = $self->generate_validation($table_name);

=head1 TODO

The work on the features may not go in the same order specified here. Some
parts may be fully implemented while others may be left for later.

    - Improve documentation.
    - Implement generation of Open API specification out from
      tables' metadata. More tests.

=head1 AUTHOR

    Красимир Беров
    CPAN ID: BEROV
    berov@cpan.org

=head1 COPYRIGHT

This program is free software licensed under

  Artistic License 2.0

The full text of the license can be found in the LICENSE file included with
this module.

=head1 SEE ALSO

L<Mojolicious::Command::generate>,
L<Mojolicious::Command>,
L<Mojolicious>,
L<Mojolicious::Plugin::OpenAPI>,
L<Perl|https://www.perl.org/>.

=cut

