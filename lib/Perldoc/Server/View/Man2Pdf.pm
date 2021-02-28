package Perldoc::Server::View::Man2Pdf;

use strict;
use warnings;
use parent 'Catalyst::View';
#use Pod::Man::TMAC;
use File::Temp;
use Perl6::Slurp;
use Encode;

sub process {
  my ($self, $c) = @_;

  my $title = $c->stash->{title};
  my $lang = $c->stash->{lang} // '';
  my $debug = 1;

  my $man_fh = File::Temp->new(UNLINK => 1, SUFFIX => '.man');
  binmode $man_fh, ":utf8" if Encode::is_utf8($c->stash->{man}); # xxxxx
  print $man_fh $c->stash->{man};
  print $man_fh ".pdfview /PageMode /UseOutlines\n";
  $man_fh->seek(0, 0);

  my $pipeline = join ' | ', grep defined,
    "cat $man_fh",
    $c->config->{man2pdf}{prepro},
    do {
      my $man2pdf =
        $c->config->{man2pdf}{$lang} ||
        $c->config->{man2pdf}{default};
      if ($man2pdf =~ /\bgroff\b/) {
        # apply preprocessor word described in groff_tmac(5)#Convention.
        $man2pdf .= " -$1" if $c->stash->{man} =~ /^'\\"\s*(\w+)/s;
      }
      $man2pdf;
    },
    $c->config->{man2pdf}{postpro};

  my $download_pdf = $c->config->{man2pdf}{download} || 'attachment';

  warn "# $pipeline\n" if $debug;
  my $pdf = slurp '-|', $pipeline;
  die "can't read pdf\n" if $! || !$pdf;
  $c->res->content_type('application/pdf');
  $c->res->header("Content-Disposition", qq[$download_pdf; filename=$title.pdf]);
  $c->res->body($pdf);
}

=encoding UTF-8

=head1 NAME

Perldoc::Server::View::Man2Pdf - Catalyst View

=head1 DESCRIPTION

Create the PDF from L<man(7)> or L<mdoc(7)> text.

Describe the command to be executed with the language name as the key
in the conf file.

    man2pdf:
      default: groff -Tpdf -k -mandoc
      ja: groff -Tpdf -k -mandoc -mja

Here's a sample that redefine the section-name with -mdoc (to fix
missing header/footer):

    man2pdf:
      ja:
        nkf -w | perl -lpe 'print ".ds section-name $1\n.lf $." if /^[.]Sh (名前|名称)/'
        | groff -Tpdf -mandoc -mja -k
      fr:
        perl -lpe 'print ".ds section-name $1\n.lf $." if /^[.]Sh (NOM|NAME\/NOM)/'
        | groff -Tpdf -mandoc -mfr -k


To embed fonts in PDF, add a filter using L<gs(1)> to the C<postpro>
entry.

    man2pdf:
      postpro: gs -sDEVICE=pdfwrite -o - -


=head1 AUTHOR

Koichi Kubo

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
