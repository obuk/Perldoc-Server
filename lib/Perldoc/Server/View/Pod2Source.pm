# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::View::Pod2Source;

use strict;
use warnings;
use parent 'Catalyst::View';

use Perldoc::Server::Convert::Verbatim;
use Encode;

sub process {
  my ($self, $c) = @_;
  my $code = $c->stash->{pod};
  $code = decode($1, $code) if $code =~ /^=encoding\s+(\S+)/m;
  my $output = Perldoc::Server::Convert::Verbatim::perltidy(
      $c, $c->stash->{title}, $code);
  $c->stash->{pod}           = $output;
  $c->stash->{page_template} = 'pod2source.tt';  
  $c->forward('View::TT');
}

=head1 NAME

Perldoc::Server::View::Pod2Source - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
