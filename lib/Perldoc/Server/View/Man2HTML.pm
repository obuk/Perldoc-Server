# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::View::Man2HTML;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::View::TT';

use Perldoc::Server::Convert::Man2HTML;

sub process {
  my ($self,$c) = @_;

  my $m2h = Perldoc::Server::Convert::Man2HTML->new($c, $c->stash->{title});
  $c->stash->{pod2html}        = $m2h->body;
  $c->stash->{page_index}      = $m2h->index;
  $c->stash->{page_template} //= 'pod2html.tt';

  $c->forward('View::TT');
}


=head1 NAME

Perldoc::Server::View::Man2HTML - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
