package Perldoc::Server::Controller::Pdf;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Controller';

sub index :Path {
  my ( $self, $c, @pod ) = @_;

  my $title = join '::', @pod;
  my $doc = $title =~ /\([^\)]+\)$/ ? 'man' : 'pod';
  my $model = $c->model(lcfirst($doc));
  $c->stash->{title}       = $title;
  $c->stash->{path}        = \@pod;
  $c->stash->{$doc}        = $model->$doc($title);
  $c->stash->{filename}    = $model->find();
  $c->stash->{lang}        = $model->lang();

  $c->forward("View::".ucfirst($doc)."2Pdf");
}

=head1 NAME

Perldoc::Server::Controller::Pdf - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

Create PDF of pods and manpages.


=head1 AUTHOR

KUBO, Koichi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
