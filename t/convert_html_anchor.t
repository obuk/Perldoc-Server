# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok 'Perldoc::Server::Convert::html' };

my $pod = <<EOT;
=head1 H1
X<h1>

X<x1>

=head2 H2
X<h2>

=over

=item item
X<i>

=back

=cut
EOT

my $c = bless { };

my $html = Perldoc::Server::Convert::html::convert($c, $0, $pod);
# warn $html;

like $html, qr{<a name="h1">.*?<a name="H1">};
like $html, qr{<a name="h2">.*?<a name="H2">};
like $html, qr{<a name="i">.*?<a name="item">};

TODO: {
  local $TODO = "handles X<> in testblock";
  like($html, qr{<a name="h1">.*?<a name="x1">.*?<a name="h2">});
};

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
