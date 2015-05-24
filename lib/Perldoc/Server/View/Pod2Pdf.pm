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

  my $cwd = getcwd;
  my $dir = tempdir(CLEANUP => 1);
  chdir $dir;
  open my $pod_fh, "<", \$c->stash->{pod};
  # open my $tex_fh, ">", \my $tex;
  open my $tex_fh, ">", "texput.tex";
  my $parser = Pod::Lualatex->new();
  $parser->parse_from_filehandle($pod_fh, $tex_fh);
  close $tex_fh;
  my $tex = slurp "<:encoding(UTF-8)", "texput.tex";
  $tex =~ s/\\end{verbatim}\n\\begin{verbatim}//sg;
  # open my $lua_fh, "|-", "lualatex";
  open my $lua_fh, "|-:encoding(UTF-8)", "lualatex";
  print $lua_fh $tex;
  close $lua_fh;
  my $pdf = slurp "texput.pdf";
  # my $log = slurp "texput.log";
  # $log =~ /Fatal error occurred, no output PDF file produced/;
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
