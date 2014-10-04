# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::Convert::Man2HTML;

use strict;
use warnings;

use IPC::Open3;
use Symbol;
use IO::File;

use Data::Dumper;

sub new {
  my $class = shift;
  my $c = shift;
  my $self = bless { c => $c };
  if (my $title = shift) {
    $self->convert($title);
  }
  $self;
}

sub convert {
  my ($self, $document_name) = @_;

  (my $title = $document_name) =~ /([^\(]+)\(([^\)]+)\)/;
  @{$self}{qw(topic section)} = ($1, $2 || 1);

  my ($body, $index);
  my ($manout, $manerr) = run('man', @{$self}{qw(section topic)});
  if ($? == 0) {
    open STDIN, "<&", $manout;
    open my $man2html, '-|:encoding(utf8)', qw(man2html --bare --nodepage -);
    my $view = $self->{c}->uri_for('/view');
    $body = join('', <$man2html>);
    $body =~ s!(<B>[^(\s]+)</B>(\s*\n\s*)<B>([^(]*[(]\d+[)]</B>)!$2$1$3!g;
    $body =~ s!<B>(([\w\.-]+)[(]\d+[)])</B>!<a href="$view/$1">$&</a>!g;
    $body =~ s/<H([12])>([^<]+)<\/H\1>/$self->add_index($1, $2)/eg;
    close $man2html;
  } else {
    $body = join('', <$manerr>);
  }
  close $manout;
  close $manerr;

  $self->{body} = $body;
}

sub add_index {
  my ($self, $i, $title) = @_;
  if ($i <= 2) {
    my $index = Perldoc::Server::Convert::html::escape($title);
    push(@{$self->{index} ||= []}, [ $i, "<a href=\"#$index\">$title</a>" ]);
    "<a name=\"$index\"></a><h$i>$title</h$i>";
  } else {
    "<h$i>$title</h$i>";
  }
}

sub body {
  my $self = shift;
  $self->{body};
}

sub index {
  my $self = shift;
  my $index = $self->{index};
  if ($index && @$index) {
    join("\n", '<ul>', (map { ('<li>', $_->[1], '</li>') } @$index), '</ul>');
  } else {
    '';
  }
}

sub run {
  local *CATCHOUT = IO::File->new_tmpfile;
  local *CATCHERR = IO::File->new_tmpfile;
  my $pid = open3(Symbol::gensym, ">&CATCHOUT", ">&CATCHERR", @_);
  waitpid($pid, 0);
  seek $_, 0, 0 for \*CATCHOUT, \*CATCHERR;
  (*CATCHOUT, *CATCHERR);
}

1;
