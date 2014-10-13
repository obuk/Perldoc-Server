# -*- mode: perl; perl-indent-level: 2; indent-tabs-mode: nil -*-

use strict;
use warnings;

# use Test::More tests => 4;
use Test::More qw(no_plan);

BEGIN { use_ok 'Perldoc::Server::Convert::html' };

use utf8;

# ============================================================
{
  my $name = 'itemize';
  my $pod = <<EOT;
=over

=item

tb1

=item

tb2

=back

=cut
EOT
    ;

  my $c = bless { };
  {
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<ul>
 <li> <p> tb1 </p> </li>
 <li> <p> tb2 </p> </li>
</ul>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, $name;
  }
  {
    $c->{feature}{item} = 'yes';
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<ul>
 <li> <p> tb1 </p> </li>
 <li> <p> tb2 </p> </li>
</ul>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, "$name-more";
  }
}


{
  my $name = 'itemize2';
  my $pod = <<EOT;
=over

=item *

tb1

=item *

tb2

=back

=cut
EOT
    ;

  my $c = bless { };
  {
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<ul>
 <li> <p> tb1 </p> </li>
 <li> <p> tb2 </p> </li>
</ul>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, $name;
  }
  {
    $c->{feature}{item} = 'yes';
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<ul>
 <li> <p> tb1 </p> </li>
 <li> <p> tb2 </p> </li>
</ul>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, "$name-more";
  }
}

# ============================================================

{
  my $name = 'enumerate';
  my $pod = <<EOT;
=over

=item 1.

tb1

=item 2.

tb2

=back

=cut
EOT
    ;

  my $c = bless { };
  {
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<dl>
  <dt>1.</dt>
  <dd> <p>tb1</p> </dd>
  <dt>2.</dt>
  <dd> <p>tb2</p> </dd>
</dl>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, $name;
  }
  {
    $c->{feature}{item} = 'yes';
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<ol>
  <li> <p>tb1</p> </li>
  <li> <p>tb2</p> </li>
</ol>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, "$name-more";
  }
}

{
  my $name = 'enumerate2';
  my $pod = <<EOT;
=over

=item 1. tx1

tb1

=item 2. tx2

tb2

=back

=cut
EOT
    ;

  my $c = bless { };
  {
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<dl>
  <dt>1. </dt>
  <dd><a name="1.-tx1"></a><b>tx1</b> <p>tb1</p> </dd>
  <dt>2. </dt>
  <dd><a name="2.-tx2"></a><b>tx2</b> <p>tb2</p> </dd>
</dl>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, $name;
  }
  {
    $c->{feature}{item} = 'yes';
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<ol>
  <li> <p><a name="tx1"></a><b>tx1</b></p> <p>tb1</p> </li>
  <li> <p><a name="tx2"></a><b>tx2</b></p> <p>tb2</p> </li>
</ol>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, "$name-more";
  }
}


# ============================================================

{
  my $name = 'description';
  my $pod = <<EOT;
=over

=item x1

tb1

=item x2

tb2

=back

=cut
EOT
    ;

  my $c = bless { };
  {
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<ul>
  <li> <a name="x1"></a><b>x1</b> <p>tb1</p> </li>
  <li> <a name="x2"></a><b>x2</b> <p>tb2</p> </li>
</ul>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, "$name-more";
  }
  {
    $c->{feature}{item} = 'yes';
    my $got = Perldoc::Server::Convert::html::convert($c, $0, $pod);
    $got =~ s/<!--.*?-->//sg;
    my $expected = <<EOT;
<dl>
  <dt><a name="x1"></a>x1</dt>
  <dd> <p>tb1</p> </dd>
  <dt><a name="x2"></a>x2</dt>
  <dd> <p>tb2</p> </dd>
</dl>
EOT
;
    $expected =~ s/\s+/\\s*/sg;
    like $got, qr/$expected/, "$name-more";
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
