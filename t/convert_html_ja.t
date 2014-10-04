# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

binmode STDOUT, ":encoding(utf-8)";
binmode STDERR, ":encoding(utf-8)";

use Test::More tests => 2;

BEGIN { use_ok 'Perldoc::Server::Convert::html' };

use utf8;

my $pod = <<EOT;
=encode utf8;

改行を
除去
する。

=cut
EOT

my $c = bless { lang => 'ja' };

my $html = Perldoc::Server::Convert::html::convert($c, $0, $pod);
# warn $html;

SKIP: {
  skip "not in ja", 1 unless $c->{lang} && $c->{lang} eq 'ja';
  like $html, qr{改行を除去する。};
}


sub config {
  shift;
}

our $module;

sub model {
  my $self = shift;
  $module = shift;
  $self;
}

sub find {
  my ($self, $page) = @_;
  diag("*** ${module}::find $page");
  undef;
}

sub exists {
  my ($self, $page) = @_;
  diag("${module}::exists $page");
  undef;
}
