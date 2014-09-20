# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::Convert::Verbatim;

use strict;
use warnings;
use HTML::Entities;
use Perl::Tidy qw();
use File::Spec;

# perltidy runs for source code pages and verbatim paragraphs.

sub perltidy {
  my ($c, $document_name, $code) = @_;

  my ($result, $error);
  Perl::Tidy::perltidy(
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
      Perl::Tidy::perltidy(
        source      => \$_,
        destination => \$result,
        argv        => ['-html','-pre'],
        errorfile   => \$error,
        stderr      => File::Spec->devnull(),
      );

      $result =~ s!\n*</?pre>\n*!!g;

      # the tidy style "q" (quote) is same as an error, so remove it
      # and adds style "w" (bareword) for \w+ to make link. tidy style
      # is defined in %Perl::Tidy::short_to_long_names.
      if ($result =~ s!^<span class="q">(.*)</span>$!$1! ||
	  $result !~ /<span\b/) {
	$result =~ s![*$@%]?\w+!<span class="w">$&</span>!g;
      }
      push(@result, $result);
    }
    $result = join("\n", "<pre>", @result, "</pre>");
  } else {
    # blank becomes doubled? in_continued_quote.
    $result =~ s!^(\s+)(<span class="q">\1)!$2!gm;
  }

  # set $show_perltidy = 1 to show the result of perltidy after the
  # verbatim paragraph.
  my $raw_result; my $show_perltidy = 0;
  $raw_result = encode_entities($result) if $show_perltidy;

  (my $site = $c->req->base) =~ s!/ajax/perlsyntax!!; # XXXXX
  $result =~ s!\$!&#36;!g;
  $result =~ s!\n*</?pre.*?>\n*!!g;
  $result =~ s!<span class="k">(.*?)</span>!($c->model('PerlFunc')->exists($1))?q(<a class="l_k" href=").qq(${site}functions/$1">$1</a>):$1!sge;
  $result =~ s!<span class="w">(.*?)</span>!($c->model('Pod')->find($1))?'<a class="l_w" href="'."${site}view/".linkpath($1).qq(">$1</a>):$1!sge;

  my $output = '<ol>';
  my @lines = split(/\r\n|\n/,$result);
  foreach (@lines) {$output .= "<li>$_</li>"}
  $output .= '</ol>';
  $output .= "<pre>$raw_result</pre>" if $show_perltidy;

  $output;
}

sub linkpath {
  my $path = shift;
  $path =~ s!::!/!g;
  return $path;
}

1;
