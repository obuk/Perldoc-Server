package Perldoc::Server::View::Pod2Pdf;

use strict;
use warnings;
use parent 'Catalyst::View';
use Pod::Lualatex;
use Cwd;
use File::Temp qw/ tempfile tempdir /;
use Perl6::Slurp;

sub process {
  my ($self, $c) = @_;

  my $pdf;
  my $dir = tempdir(CLEANUP => 1);
  # my $dir = 'tmp'; mkdir $dir;
  my $cwd = getcwd;
  chdir $dir;
  open my $in_fh, "<", \$c->stash->{pod};
  open my $out_fh, ">", "texput.tex";
  my $parser = Pod::Lualatex->new();
  $parser->parse_from_filehandle($in_fh, $out_fh);
  close $in_fh;
  close $out_fh;
  open STDIN, '<', '/dev/null';
  system "lualatex", "texput.tex" for 1..2;
  eval { $pdf = slurp "texput.pdf" };
  die "can't convert into pdf; install tex-luatex\n" if $@;
  unlink glob "texput.*";
  chdir $cwd;
  rmdir $dir;

  (my $pdf_filename = $c->stash->{title}) =~ s/(::|\/|\s+)/-/g;
  $pdf_filename .= '.pdf' unless ($pdf_filename =~ /\.pdf$/i);

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
