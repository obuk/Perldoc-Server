package Perldoc::Server::Model::Pod;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Model';

use File::Slurp qw/slurp/;
use Memoize;
use Pod::Simple::Search;

memoize('section', NORMALIZER => sub { $_[1] });

sub ACCEPT_CONTEXT { 
  my ( $self, $c, @extra_arguments ) = @_; 
  bless { %$self, c => $c }, ref($self); 
}


sub pod {
  my ($self,$pod) = @_;
  
  if (my $file = $self->find($pod)) {
    return slurp($file);
  }
  
  return "=head1 Cannot find Pod for $pod";
}

sub search_path {
  my ($self) = @_;
  my @search_path = ();
  if (my $lang = $self->{c}->config->{lang}) {
    if (my $tr = $self->new_translator($lang)) {
      if ($tr->can('pod_dirs')) {
        push @search_path, $tr->pod_dirs();
      } else {
        (my $dir = $INC{"POD2/\U$lang\E.pm"}) =~ s/\.pm\z//;
        warn "*** can't $tr->pod_dirs(); adds $dir\n";
        push @search_path, $dir;
      }
    }
  }
  push @search_path, @{$self->{c}->config->{search_path}};
  grep {/\w/} @search_path;
}

sub search_perlfunc_re {
  my ($self) = @_;
  my @search_path = ();
  if (my $lang = $self->{c}->config->{lang}) {
    if (my $tr = $self->new_translator($lang)) {
      if ($tr->can('search_perlfunc_re')) {
        return $tr->search_perlfunc_re();
      }
    }
  }
  undef;
}

sub version {
  my ($self, $name) = @_;
  my $tr = $self->new_translator($self->{c}->config->{lang});
  return undef unless $tr && $tr->can('pod_info');
  return undef unless my $info = $tr->pod_info;
  $info->{lc $name};
}

sub new_translator { # $tr = $self->new_translator($lang);
  my $self = shift;
  my $lang = shift;

  my $pack = 'POD2::' . uc($lang);
  eval "require $pack";
  unless ($@) {
    return $pack->can('new')? $pack->new() : $pack;
  }

  eval { require POD2::Plus };
  return POD2::Plus->new({ lang => $lang }) unless $@;

  eval { require POD2::Base };
  return if $@;

  return POD2::Base->new({ lang => $lang });
}

sub find {
  my ($self,$pod) = @_;
  
  return () unless $pod;
  my @search_path = $self->search_path;
  return Pod::Simple::Search->new->inc(0)->find($pod, @search_path,map{"$_/pods"} @search_path);
}


sub title {
  my ($self,$page) = @_;
  state %name2title;
  
  unless (exists $name2title{$page}) {
    if (my $file = $self->find($page)) {
      if (my $title = $self->parse_abstract($page, $file)) {
        $title =~ s/E<(.*?)>/&$1;/g;
        $title =~ s/[A-DF-Z]<(.*?)>/$1/g;
        $title =~ s/.*? -+\s+//;
        $title =~ s/\(\$.*?\$\)//;
        $name2title{$page} = $title;
      }
    }
  }
  
  return $name2title{$page};
}

# added =encoding based on ExtUtils/MM_Unix.pm
sub parse_abstract {
  my($self, $page, $parsefile) = @_;
  my $result;

  local $/ = "\n"; local $_;
  open(my $fh, '<', $parsefile) or die "Could not open '$parsefile': $!";
  my $inpod = 0; my $binmode; my @begin;
  while (<$fh>) {
    $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
    next if !$inpod;
    chop;
    $binmode ||= /^=encoding\s+(\S+)/ && binmode($fh, ":encoding($1)");
    if (/^=begin\s+(\S+)/) {
      push(@begin, $1);
    } elsif (/^=end\s+(\S+)/ && @begin && $begin[-1] eq $1) {
      pop(@begin);
    } elsif (@begin) {
      next;
    }
    if ( /^($page(?:\.pm)?\s+ -+ \s+)(.*)/ix ) {
      $result = $2;
      next;
    }
    next unless $result;
    if ( $result && ( m/^\s*$/ || m/^\=/ ) ) {
      last;
    }
    $result = join ' ', $result, $_;
  }
  close $fh;
  return $result;
}


sub section {
  my ($self, $page) = @_;
  
  foreach my $section ($self->{c}->model('Section')->list) {
    my @section_pages = $self->{c}->model('Section')->pages($section);
    if ($page ~~ @section_pages) {
      return $section;
    }
  }
  return;
}

=head1 NAME

Perldoc::Server::Model::Pod - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
