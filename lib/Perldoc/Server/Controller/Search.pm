# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::Controller::Search;

use strict;
use warnings;
use 5.010;
use experimental qw(smartmatch);
use parent 'Catalyst::Controller';

use Perldoc::Server::View::Pod2HTML;

=head1 NAME

Perldoc::Server::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ($self, $c) = @_;

  if (my $query = $c->req->param('q')) { 
    my @functions = $c->model('PerlFunc')->list;
    my @pages     = sort {$a cmp $b} $c->model('Index')->find_modules;

    given ($query) {
      when (@functions) {
        return $c->response->redirect( $c->uri_for('/functions',$query) );
      }
      when (@pages) {
        return $c->response->redirect( $c->uri_for('/view',split('::',$query)) );
      }
      when (/^($query)$/i ~~ @pages) {
        my $matched_page = $1;
        return $c->response->redirect( $c->uri_for('/view',split('::',$matched_page)) );
      }
      when (/^($query.*)$/i ~~ @pages) {
        my $matched_page = $1;
        return $c->response->redirect( $c->uri_for('/view',split('::',$matched_page)) );
      }
      when (/(\.(pod|pm|pl)|\([^\)]+\))$/) {
        return $c->response->redirect( $c->uri_for('/view', $query) );
      }
    }

    # search more - it will be slow.
    my @perldoc = ('perldoc');
    if (my $lang = $c->config->{lang}) {
      push @perldoc, '-L', $lang;
    }
    my $v = `@perldoc -v '$query'`;
    if ($? == 0) {
      warn "@perldoc -v '$query' >/dev/null\n";
      return $c->response->redirect( $c->uri_for("/view/perlvar#$query") );
    }
    
    my $q = `@perldoc -u -q '$query'`;
    if ($? == 0) {
      $q =~ s!^(=head1 Found in).*/([^/]+pod)$!$1 $2!mg;
      $c->stash->{pod} = $q;
      $c->stash->{title} = "perldoc -q '$query'";
      return Perldoc::Server::View::Pod2HTML->process($c);
    }

    $c->stash->{query} = $query;
  }
  
  $c->stash->{page_name}     = 'Search results';
  $c->stash->{page_template} = 'search_results.tt';
}


=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
