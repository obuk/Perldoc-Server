# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::View::Man2Source;

use strict;
use warnings;
use feature 'say';
use parent 'Catalyst::View';

use HTML::Element;
use Encode;

sub process {
  my ($self, $c) = @_;

  my $html = $self->pretty_html($c->stash->{man});
  $c->stash->{pod} = $html->as_HTML;

  $c->stash->{page_template} = 'pod2source.tt';
  $c->forward('View::TT');
}

sub ec {
  my $self = shift;
  $self->{ec} = shift if @_;
  $self->{ec};
}

sub cc {
  my $self = shift;
  $self->{cc} = shift if @_;
  $self->{cc};
}

sub c2 {
  my $self = shift;
  $self->{c2} = shift if @_;
  $self->{c2};
}

sub ft {
  my ($self, $font) = @_;
  if ($font) {
    if ($font eq 'P') {
      $self->{ft} = $self->{prev_ft};
    } else {
      $self->{prev_ft} = $self->{ft};
      $self->{ft} = $font;
    }
  }
  $self->{ft};
}

sub pua {
  my $self = shift;
  $self->{pua} //= 0xF0000;
  pack "U*", $self->{pua}++;
}

sub unget {
  my $self = shift;
  $self->{lines} //= [];
  for (@_) {
    for (reverse split /\n/) {
      $self->{linecount}--;
      unshift @{$self->{lines}}, $_;
    }
  }
}

sub getline {
  my $self = shift;
  if (@{$self->{lines}}) {
    my $ec = $self->ec;
    my $ee = $ec.$ec;
    my @line;
    $self->{linecount} += $self->{_linecount};
    $self->{_linecount} = 0;
    do {
      $self->{_linecount}++;
      push @line, shift @{$self->{lines}};
    } while (@{$self->{lines}} && $line[-1] =~ /${ee}$/);
    join "\n", @line;
  } else {
    undef;
  }
}

sub linecount {
  my $self = shift;
  $self->{linecount} = shift, $self->{_linecount} = 0 if @_;
  $self->{linecount};
}

sub pretty_html {
  my ($self, $man) = @_;

  $self->unget($man);
  $self->linecount(1);

  $self->ec("\\");
  $self->ft("R");
  $self->cc(".");
  $self->c2("'");

  my @define;
  my $end_default = ".";

  my %class = (
    comment => 'c',
    preproc => 'hh',
    define  => 'q',
    request => 'v',
    character => 'i',
    escape => 'n',
  );

  my $html = HTML::Element->new('ol');
  my $in_preproc = 0;
  while (defined (local $_ = $self->getline)) {

    my $ee = join '', ($self->ec) x 2;
    my $cc = '['.(join '', $self->cc, $self->c2).']';

    if (/^$cc/ || @define || $in_preproc) {
      my %attr = (class => $class{request});
      if (/^$cc\s*(ig|de1?i?|am1?i?)(?:\s+(.*?)(?:\s*$ee["#].*)?)?$/) {
        my ($name, $args) = ($1, $2 // '');
        my $end = join '', map "[$_]", split //,
          (split /\s+/, $args)[1] || $end_default;
        $attr{class} = $name eq 'ig' ? $class{comment} : $class{define};
        push @define, { name => $name, end => $end, class => $attr{class} };
      } elsif (@define) {
        $attr{class} = $define[-1]->{class};
        pop @define if /^$cc\s*$define[-1]->{end}$/;
      } elsif (/^($cc)\s*$ee\"/) {
        $attr{class} = $class{comment};
        $attr{class} = $class{preproc} if $self->linecount == 1 && $1 eq $self->c2;
      } elsif (/^$cc\s*(cc|c2)(?:\s+(.*?)(?:\s*$ee["#].*)?)?$/) {
        $self->$1($2);
      }
      $in_preproc++ if /^$cc\s*(TS|EQ|PS|GS|R1)\b/;
      $attr{class} = $class{preproc} if $in_preproc;
      $in_preproc-- if /^$cc\s*(TE|EN|PE|G[EF]|R2)\b/;
      $in_preproc = 0 if $in_preproc < 0;
      for (split /\n/) {
        my $line = HTML::Element->new('li');
        my $span = HTML::Element->new('span', %attr);
        $span->push_content($_);
        $line->push_content($span);
        $html->push_content($line);
      }
    } else {
      my $line = HTML::Element->new('li');
      while (
        s{^
          ( .*? )						# $1 $text
          (?:
            (   $ee (?: (?&NAME) )                      ) |	# $2 $chr
            (?: $ee [!] .* $                            ) |
            (?: $ee [?] .*? $ee [?]                     ) |
            (   $ee ["#] .* $                           ) |	# $3 $comment
            (?: $ee [O] (?: \d | (?&name) )             ) |
            (?: $ee [n] [+-]? (?: (?&NAME) | . )        ) |
            (?: $ee [s] (?&SIZE)                        ) |
            (   $ee [\n]                                ) |	# $4 $ret
            (   $ee [\w\$\*] (?: (?&NAME) | '.*?' | . ) ) |	# $5 $esc_f
            (   $ee .                                   )	# $6 $any
          )
          (?(DEFINE)
            (?<nm>   (?: \( .. ))
            (?<name> (?: \[ [^\]]* \] ))
            (?<NAME> (?: (?&nm) | (?&name) ))
            (?<SIZE> (?: \d | \d\d | [+-]\d | \(\d\d | [+-]\(\d\d | \([+-]\d\d ))
          )}{}xs) {
        my ($text, $chr, $comment, $ret, $esc_f, $any) = ($1, $2, $3, $4, $5, $6);
        unless ($text || $chr || $comment || $ret || $esc_f || $any) {
          ($any = $&) =~ s/.*?($ee)/$1/;
          #warn "# ", $self->linecount, ": unknown escape sequence: '$any'\n";
        }
        if (local $_ = $text) {
          my $span = HTML::Element->new('span', class => "f".$self->ft);
          $span->push_content($_);
          $line->push_content($span);
        }
        if (local $_ = $chr) {
          my $span = HTML::Element->new('span', class => $class{character});
          $span->push_content($_);
          $line->push_content($span);
        } elsif (local $_ = $comment) {
          my $span = HTML::Element->new('span', class => $class{comment});
          $span->push_content($_);
          $line->push_content($span);
        } elsif (local $_ = $esc_f) {
          my $span = HTML::Element->new('span', class => $class{escape});
          $span->push_content($_);
          $line->push_content($span);
          if (/^${ee}f(.*)/) {
            (my $x = $1) =~ s/^(?:\(|\[)|\]$//g;
            if ($x eq 'P' || $x eq '') {
              $self->ft($self->ft('P'));
            } else {
              $self->ft($x);
            }
          }
        } elsif (local $_ = $ret) {
          my $span = HTML::Element->new('span', class => "f".$self->ft);
          $span->push_content($_);
          $line->push_content($span);
          $html->push_content($line);
          $line = HTML::Element->new('li');
        } elsif (local $_ = $any) {
          my $span = HTML::Element->new('span', class => "f".$self->ft);
          $span->push_content($_);
          $line->push_content($span);
        }
      }

      if (/./) {
        my $span = HTML::Element->new('span', class => "f".$self->ft);
        $span->push_content($_);
        $line->push_content($span);
      }

      $html->push_content($line);
    }
  }
  $html;
}

=head1 NAME

Perldoc::Server::View::Man2Source - Catalyst View

=head1 DESCRIPTION

View the manpage source.

I've tried a few colorings, mimicking
L<Perldoc::Server::View::Pod2Source> for readability, but it's
unlikely that the effort will pay off.

=head1 AUTHOR

Kubo, Koichi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
