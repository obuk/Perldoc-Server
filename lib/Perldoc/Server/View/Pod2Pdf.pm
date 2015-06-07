package Perldoc::Server::View::Pod2Pdf;

use strict;
use warnings;
use parent 'Catalyst::View';
use Pod::Lualatex;
use File::Temp qw/ tempdir /;
use File::Spec::Functions qw/ catfile /;
use File::Slurp qw/ read_file write_file /;
use Digest::MD5 qw/ md5_base64 /;
use Encode;

sub process {
  my ($self, $c) = @_;

  (my $pdf_filename = $c->stash->{title}) =~ s/(::|\/|\s+)/-/g;
  $pdf_filename .= '.pdf' unless ($pdf_filename =~ /\.pdf$/i);

  my ($pdf, $pdf_cache);
  my ($md5, $md5_cache) = md5_base64($c->stash->{pod});

  if (my $cache = $ENV{PDF_CACHE}) {
    $cache = undef unless -d $cache;
    if ($cache) {
      $pdf_cache = catfile $cache, $pdf_filename;
      ($md5_cache = $pdf_cache) =~ s/\.pdf$/.md5/;
    }
    if (-r $md5_cache && -r $pdf_cache &&
          $md5 eq read_file($md5_cache)) {
      $pdf = read_file $pdf_cache;
    }
  }

  unless ($pdf) {
    my $tempdir = tempdir(CLEANUP => 1);
    # my $tempdir = 'tmp'; mkdir $tempdir unless -d $tempdir;
    my $texput_tex = catfile $tempdir, 'texput.tex';
    my $texput_pdf = catfile $tempdir, 'texput.pdf';
    my $texput_log = catfile $tempdir, 'texput.log';
    open my $in_fh, "<", \$c->stash->{pod};
    open my $out_fh, ">", $texput_tex;
    my $parser = Pod::Lualatex->new();
    $parser->parse_from_filehandle($in_fh, $out_fh);
    close $in_fh;
    close $out_fh;
    my $cmd = join('; ', "chdir $tempdir", ("cat texput.tex | lualatex") x 2);
    system "($cmd)";
    die "can't run lualatex\n" if $@;
    chop(my @log = read_file($texput_log));
    if (grep { /Fatal error occurred/ } @log) {
      @log = map { eval { decode('UTF-8', $_) } // '' } @log;
      $c->stash->{pod2html} = join("\n", '<pre>', @log, '</pre>');
      $c->stash->{page_template} = 'pod2html.tt';
      $c->forward('View::TT');
      return;
    }
    $pdf = read_file $texput_pdf;
    die "can't read $texput_pdf\n" unless $pdf;
    if ($pdf_cache) {
      write_file($pdf_cache, $pdf);
      write_file($md5_cache, $md5);
    }
    unlink glob catfile($tempdir, '*');
    rmdir $tempdir if -d $tempdir;
  }

  # my $pdf_disposition = 'attachment';
  my $pdf_disposition = 'inline';
  $c->response->content_type('application/pdf');
  $c->response->headers->header(
    "Content-Disposition" => qq{$pdf_disposition; filename="$pdf_filename"}
   );
  $c->response->body($pdf);
}

=head1 NAME

Perldoc::Server::View::Pod2Source - Catalyst View

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
