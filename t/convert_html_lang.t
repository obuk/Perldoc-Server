# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

binmode STDOUT, ":encoding(utf-8)";
binmode STDERR, ":encoding(utf-8)";

use Test::More tests => 4;

BEGIN { use_ok 'Perldoc::Server::Convert::html' };

use utf8;

{
  my $pod = <<EOT;
=encode utf8;

改行を
除去
する。

=cut
EOT

  my $c = bless { lang => 'ja' };
  my $html = Perldoc::Server::Convert::html::convert($c, $0, $pod);
  like $html, qr{改行を除去する。};
}

{
  my $pod = <<EOT;
=pod

Pod is a simple-to-use markup language used for writing documentation
for Perl, Perl programs, and Perl modules.

=cut
EOT

  (my $pat = $pod) =~ s/\n*(=\w+)\n+/\n/sg;
  $pat =~ s/^\s+|\s$/\\s*/sg;
  $pat =~ s/\s+/\\s+/sg;
  $pat =~ s/[.]/\\$&/g;

  {
    my $c = bless { lang => undef };
    my $html = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    like $html, qr{$pat};
  }

  {
    my $c = bless { lang => 'ja' };
    my $html = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    like $html, qr{$pat};
  }
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
