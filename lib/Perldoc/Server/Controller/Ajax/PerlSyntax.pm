package Perldoc::Server::Controller::Ajax::PerlSyntax;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use File::Spec;
use HTML::Entities;
use OpenThought;

use HTML::Entities;
use CGI::Util qw(unescape);
use Encode;

=head1 NAME

Perldoc::Server::Controller::Ajax::PerlSyntax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;
  my $id   = $c->req->param('id');
  my $code = $c->req->param($id);
  $code = decode_entities($code);
  $code =~ s/%u[\da-fA-F]{4,}/decode('utf8', unescape($&))/ge;
  my $output = Perldoc::Server::Convert::html::perltidy(
      $c, $c->stash->{title}, $code);
  push @{$c->stash->{openthought}}, {$id => $output};
  $c->detach('View::OpenThoughtTT');
}

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
