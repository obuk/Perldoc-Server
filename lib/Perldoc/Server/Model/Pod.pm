package Perldoc::Server::Model::Pod;

use strict;
use warnings;
use 5.010;
use experimental qw(smartmatch);
use parent 'Catalyst::Model';

use File::Slurp qw/slurp/;
use Memoize;
use Pod::POM;
use Pod::POM::View::Text;
use Pod::Simple::Search;
use Encode;
use utf8;

memoize('section', NORMALIZER => sub { $_[1] });

sub ACCEPT_CONTEXT { 
  my ( $self, $c, @extra_arguments ) = @_; 
  bless { %$self, c => $c }, ref($self); 
}


sub pod {
  my ($self,$pod) = @_;
  
  if (my $file = $self->find($pod)) {
    my $pod = slurp $file;
    unless ($self->{lang}) {
      my $lang_hint = $self->{c}->config->{lang}{hint};
      $lang_hint = undef unless ref($lang_hint) eq 'HASH';
      open my $pod_fh, "<", \$pod;
    get_lang:
      while (<$pod_fh>) {
        if (my ($encoding) = /^=encoding\s+(\S+)/) {
          binmode $pod_fh, ":encoding($encoding)";
          my ($lang_cc) = $encoding =~ /^([^\.]+)\./;
          my ($lang, $cc) = split /_/, $lang_cc || '';
          $self->{lang} //= $lang, last get_lang if $lang;
        }
        if ($lang_hint) {
          if (my ($word) = /^=head1\s+(.*?)\s*$/) {
            for my $lang (keys %$lang_hint) {
              my $hint = $lang_hint->{$lang};
              $self->{lang} //= $lang, last get_lang if $word =~ /^(?:$hint)$/;
            }
          }
        }
      }
      close $pod_fh;
    }
    return $pod;
  }
  
  return "=head1 Cannot find Pod for $pod";
}

sub search_path {
  my ($self) = @_;
  my @search_path = ();
  my $c = $self->{c};
  my $lang = $c->req->params->{lang} || $c->config->{lang}{default} || $c->config->{lang};
  if ($lang) {
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
  my %seen;
  grep { /\w/ && !$seen{$_}++ } @search_path;
}

sub search_perlfunc_re {
  my ($self) = @_;
  my $lang = $self->lang();
  if ($lang) {
    if (my $tr = $self->new_translator($lang)) {
      if ($tr->can('search_perlfunc_re')) {
        return $tr->search_perlfunc_re();
      }
    }
  }
  undef;
}

#sub version {
#  my ($self, $name) = @_;
#  my $tr = $self->new_translator($self->{c}->config->{lang}); # xxxxx
#  return undef unless $tr && $tr->can('pod_info');
#  return undef unless my $info = $tr->pod_info;
#  $info->{lc $name};
#}

sub new_translator { # $tr = $self->new_translator($lang);
  my $self = shift;
  my $lang = shift;

  my $pack = 'POD2::' . uc($lang);
  eval "require $pack";
  unless ($@) {
    return $pack->can('new')? $pack->new() : $pack;
  }

  eval { require POD2::Base };
  return if $@;

  return POD2::Base->new({ lang => $lang });
}

sub find {
  my ($self,$pod) = @_;
  
  return () unless $pod;

  $self->{lang} = undef;
  my $c = $self->{c};
  my $lang = $c->req->params->{lang} || $c->config->{lang}{default} || $c->config->{lang};
  if ($lang) {
    for (grep $self->can($_), "${lang}_find") {
      my @found = $self->$_($pod);
      last if @found;
    }
  }

  my @search_path = $self->search_path;
  if (my $filename = Pod::Simple::Search->new->inc(1)->find($pod, @search_path, map{"$_/pods"} @search_path)) {
    $self->{lang} = lc($1) if $filename =~ m{/POD2/([^/]+)/};
    return $filename;
  }
  return ();
}

sub lang {
  my ($self,$pod) = @_;

  $self->find($pod) if $pod;
  $self->{lang};
}

sub title {
  my ($self,$page) = @_;
  state %name2title;
  
  unless (exists $name2title{$page}) {
    if (my $file = $self->find($page)) {
      my $parser = Pod::POM->new();
      my $pom = $parser->parse_file($file) or die $parser->error();
      my ($head) = $pom->head1();
      for (split "\n", $head->content->present('Pod::POM::View::Text')) {
        $name2title{$1} = $2 if /^([a-z]\S+)\s+-+\s+(\S.*)/i;
      }
    }
  }
  
  return $name2title{$page};
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
