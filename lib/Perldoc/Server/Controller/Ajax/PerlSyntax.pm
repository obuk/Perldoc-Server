package Perldoc::Server::Controller::Ajax::PerlSyntax;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use File::Spec;
use HTML::Entities;
use OpenThought;
use Perl::Tidy;

use HTML::Entities;
use CGI::Util qw(unescape);
use Encode;

=head1 NAME

Perldoc::Server::Controller::Ajax::PerlSyntax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  my $id   = $c->req->param('id');
  my $code = $c->req->param($id);
  
  $code = decode_entities($code);

  # fixes utf-8 strings in verbatim paragraphs, and reduces the damage
  # in the error of perltidy that may be caused by utf-8. the damage
  # makes dizzy paragraphs.

  # the utf-8 escaped strings that passed from OpenThought.js. but
  # puts the fixes here with perltidy experimentally.  because I don't
  # know how the OpenThought.js works.

  $code =~ s/%u[\da-fA-F]{4,}/decode('utf8', unescape($&))/ge;

  my ($result,$error);
  perltidy(
    source      => \$code,
    destination => \$result,
    argv        => ['-html','-pre'],
    errorfile   => \$error,
    stderr      => File::Spec->devnull(),
  );
  
  # run perltidy for each line to reduce the damage if error.
  if ($error) {
      my @result;
      for (split("\n", $code)) {
	  ($result, $error) = ();
	  perltidy(
	      source      => \$_,
	      destination => \$result,
	      argv        => ['-html','-pre'],
	      errorfile   => \$error,
	      stderr      => File::Spec->devnull(),
	      );

	  $result =~ s!\n*</?pre>\n*!!g;

	  # the tidy style "q" (quote) is same as error, so remove it
	  # and adds style "w" (bareword) for \w+ to make link. tidy
	  # style is defined in %Perl::Tidy::short_to_long_names.
	  if ($result =~ s!^<span class="q">(.*)</span>$!$1! ||
	      $result !~ /<span\b/) {
	      $result =~ s!\w+!<span class="w">$&</span>!g;
	  }
	  push(@result, $result);
      }
      $result = join("\n", "<pre>", @result, "</pre>");
  }

  # set $show_perltidy = 1 to show the result of perltidy after the
  # verbatim paragraph.
  my $raw_result; my $show_perltidy = 0;
  $raw_result = encode_entities($result) if $show_perltidy;

  $result =~ s!\$!&#36;!g;
  $result =~ s!\n*</?pre.*?>\n*!!g;
  $result =~ s!<span class="k">(.*?)</span>!($c->model('PerlFunc')->exists($1))?q(<a class="l_k" href=").qq(/functions/$1">$1</a>):$1!sge;
  $result =~ s!<span class="w">(.*?)</span>!($c->model('Pod')->find($1))?'<a class="l_w" href="/view/'.linkpath($1).qq(">$1</a>):$1!sge;

  my $output = '<ol>';
  my @lines = split(/\r\n|\n/,$result);
  foreach (@lines) {$output .= "<li>$_</li>"}
  $output .= '</ol>';
  $output .= "<pre>$raw_result</pre>" if $show_perltidy;

  push @{$c->stash->{openthought}}, {$id => $output};
  $c->detach('View::OpenThoughtTT');
}


sub linkpath {
  my $path = shift;
  $path =~ s!::!/!g;
  return $path;
}

=head1 AUTHOR

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
