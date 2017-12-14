package Blog;
use Mojo::Base 'Mojolicious';

use Blog::Model::Posts;
use Mojo::SQLite;

sub startup {
  my $self = shift;

  # Configuration
  $self->plugin('Config');
  $self->secrets($self->config('secrets'));

  # Model
  $self->helper(sqlite => sub { state $sql = Mojo::SQLite->new->from_filename(shift->config('sqlite')) });
  $self->helper(
    posts => sub { state $posts = Blog::Model::Posts->new(sqlite => shift->sqlite) });

  # Migrate to latest version if necessary
  my $path = $self->home->child('migrations', 'blog.sql');
  $self->sqlite->auto_migrate(1)->migrations->name('blog')->from_file($path);

  # Controller
  my $r = $self->routes;
  $r->get('/' => sub { shift->redirect_to('posts') });
  $r->get('/posts')->to('posts#index');
  $r->get('/posts/create')->to('posts#create')->name('create_post');
  $r->post('/posts')->to('posts#store')->name('store_post');
  $r->get('/posts/:id')->to('posts#show')->name('show_post');
  $r->get('/posts/:id/edit')->to('posts#edit')->name('edit_post');
  $r->put('/posts/:id')->to('posts#update')->name('update_post');
  $r->delete('/posts/:id')->to('posts#remove')->name('remove_post');
}

1;
