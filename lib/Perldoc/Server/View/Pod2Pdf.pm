package Perldoc::Server::View::Pod2Pdf;

use strict;
use warnings;
use feature 'say';
use parent 'Catalyst::View';
use Pod::Man::TMAC;
use File::Temp;
use Perl6::Slurp;
use Encode;
use utf8;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;

sub process {
  my ($self, $c) = @_;

  my $title = $c->stash->{title};
  my $lang = $c->stash->{lang} // '';
  my $debug = 1;

  my $pod2pdf =
    $c->config->{pod2pdf}{$lang} ||
    $c->config->{pod2pdf}{default} ||
    { };

  my %pod2pdf = (%$pod2pdf, name => $c->stash->{title});
  warn "# Pod::Man::TMAC->new(", do {
    (my $opts = Dumper(\%pod2pdf)) =~ s/\s+/ /g;
    $opts =~ s/^\s+|\s+$//g;
    $opts;
  }, ")\n" if $debug;


  my $man_fh = File::Temp->new(UNLINK => 1, SUFFIX => '.man');
  binmode $man_fh, ":utf8" if $pod2pdf{utf8};
  open my $pod_fh, "<", \$c->stash->{pod};
  my $parser = Pod::Man::TMAC->new(%pod2pdf);
  $parser->parse_from_file($pod_fh, $man_fh);
  close $pod_fh;

  print $man_fh ".pdfview /PageMode /UseOutlines\n";
  $man_fh->seek(0, 0);

  $c->stash->{man} = slurp $man_fh;
  $c->forward('View::Man2Pdf');
}

=head1 NAME

Perldoc::Server::View::Pod2Pdf - converts pod to pdf

=head1 DESCRIPTION

Create L<man(7)> text from the L<pod|perlpod> and send it to
L<Perldoc::Server::View::Man2Pdf>.

Language-dependent corrections are described in the conf file as
parameters for L<Pod::Man::TMAC>.

    pod2pdf:
      ja:
        utf8: 1
        add_preamble: pod2manja.tmac
        search_path: [ '.', '/etc/groff' ]

=head1 SEE ALSO

L<Perldoc::Server::Model::Pod>

=head1 AUTHOR

Koichi Kubo

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
