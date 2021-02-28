# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::Controller::View;

use strict;
use warnings;
use 5.010;
use experimental qw(smartmatch);
use parent 'Catalyst::Controller';

=head1 NAME

Perldoc::Server::Controller::View - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path {
    my ( $self, $c, @pod ) = @_;
    
    my $page = join '::',@pod;
    $c->stash->{title}       = $page;
    $c->stash->{path}        = \@pod;
    $c->stash->{contentpage} = 1;

    if ($page =~ /\([^\)]+\)$/) {
      my $model = $c->model('Man');
      $c->stash->{man}  = $model->man($page);
      $c->stash->{lang} = $model->lang;
      return $c->forward('View::Man2HTML');
    } else {
      my $model = $c->model('Pod');
      $c->stash->{pod}  = $model->pod($page);
      $c->stash->{lang} = $model->lang;
    }
#    if (my $v = $c->model('Pod')->version($page)) {
#      $c->stash->{version} = version->parse($v)->stringify;
#    }
    
    # Count the page views in the user's session
    my $uri = join '/','/view',@pod;
    $c->session->{counter}{$uri}{count}++;
    $c->session->{counter}{$uri}{name} = $page;
    
    given ($page) {
        when ($c->model('Pod')->section($_)) {
            my $section = $c->model('Pod')->section($_);
            #$c->log->debug("Found $page in section $section");
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index',$section), name => $c->model('Section')->name($section) },                
            ];
        }
        when (/^([A-Z])/) {
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index/modules'), name => 'Modules' },
                { url => $c->uri_for('/index/modules',$1), name => $1 },
            ];
            $c->stash->{source_available} = 1;
        }
        default {
            $c->stash->{breadcrumbs} = [
                { url => $c->uri_for('/index/pragmas'), name => 'Pragmas' },
            ];
        }
    }
    
    $c->forward('View::Pod2HTML');
}


=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
