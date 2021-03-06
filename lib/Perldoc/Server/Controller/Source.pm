package Perldoc::Server::Controller::Source;

use strict;
use warnings;
use 5.010;
use experimental qw(smartmatch);
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::Source - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path {
    my ( $self, $c, @pod ) = @_;
    
    my $title = join '::',@pod;
    $c->stash->{title}       = $title;
    $c->stash->{path}        = \@pod;
    $c->stash->{source_view} = 1;

    if ($title =~ /\([^\)]+\)$/) {
      my $model = $c->model('Man');
      $c->stash->{man}  = $model->man($title);
      $c->stash->{lang} = $model->lang;
      $c->stash->{filename} = $model->find($title); # xxxxx
      return $c->forward('View::Man2Source');
    } else {
      my $model = $c->model('Pod');
      $c->stash->{pod}  = $model->pod($title);
      $c->stash->{lang} = $model->lang;
      $c->stash->{filename} = $model->find($title); # xxxxx
    }

    given ($title) {
        when (/^([A-Z])/) {
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index/modules'), name => 'Modules' },
                { url => $c->uri_for('/index/modules',$1), name => $1 },
            ];
        }
        default {
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index/pragmas'), name => 'Pragmas' },
            ];
        }
    }
    
    $c->forward('View::Pod2Source');
}


=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
