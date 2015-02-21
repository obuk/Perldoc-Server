# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;
use Test::More tests => 8;
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

{
  my $c = bless { feature => { pod => { index => 1, item => 1 } } };
  my $html = Perldoc::Server::Convert::html::convert($c, $0, $pod);
  like $html, qr{<a name="h1"></a><a name="H1">};
  like $html, qr{<a name="h2"></a><a name="H2">};
  like $html, qr{<a name="i"></a><a name="item">};

 TODO: {
   local $TODO = "handles X<> in testblock";
   like($html, qr{<a name="h1"></a><a name="x1"></a><a name="h2">});
  };
}

{
  my $c = bless { feature => { pod => { index => 0, item => 1 } } };
  my $html = Perldoc::Server::Convert::html::convert($c, $0, $pod);
  unlike $html, qr{<a name="h1"></a>};
  unlike $html, qr{<a name="h2"></a>};
  unlike $html, qr{<a name="i"></a>};
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
