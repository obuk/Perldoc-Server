package Perldoc::Server::Controller::Pdf;

use strict;
use warnings;
use 5.010;
#use experimental qw(smartmatch);
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::Pdf - Catalyst Controller

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
  $c->stash->{pod}         = $c->model('Pod')->pod($title);
  $c->stash->{filename}    = $c->model('Pod')->find($title);

  $c->forward('View::Pod2Pdf');
}


=head1 AUTHOR

KUBO, Koichi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
