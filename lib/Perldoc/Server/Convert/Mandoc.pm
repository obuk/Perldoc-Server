# -*- perl-indent-level: 2; indent-tabs-mode: nil -*-

package Perldoc::Server::Convert::Mandoc;

use strict;
use warnings;

use File::Temp;
use File::Spec::Functions qw/ catfile /;
use HTML::TreeBuilder;
use HTML::Entities;
use Data::Dumper;
use Perl6::Slurp;
use Encode;
use utf8;

sub new {
  my $class = shift;
  my $c = shift;
  my $self = bless { c => $c };
  $self->convert(@_) if @_;
  $self;
}

sub convert {
  my ($self, $document_name, $man) = @_;
  my $c = $self->{c};

  my $man_fh = File::Temp->new(UNLINK => 1, SUFFIX => '.man');
  #my $lang = $self->{c}->req->params->{lang} || $self->{c}->config->{lang}{default} || $self->{c}->config->{lang};
  my $lang = $c->stash->{lang} // '';
  my $title = $document_name;
  warn "# man -u $title >$man_fh\n";
  binmode $man_fh, ":utf8" if Encode::is_utf8($c->stash->{man});
  print $man_fh <<END;
.nr mandoc 1
.nr __mandoc__ 1
.lf 1
END
  print $man_fh $c->stash->{man};

  my @mandoc = ("mandoc", -T => "html", -K => "utf-8");

  # preproc word
  push @mandoc, "-$1"
    if $mandoc[0] =~ /groff/ && $c->stash->{man} =~ /^\'\\"\s+(\w+)\b/s;

  # grog
  push @mandoc, $1 eq "SH" ? "-man" : $1 eq "Sh" ? "-mdoc" : ()
    if $c->stash->{man} =~ /^.\s*(S[Hh])\b/m;

  push @mandoc, '-O' => join ',' =>
    'fragment', 'man='.$c->uri_for('/view/%N(%S)');

  warn "# @mandoc <$man_fh\n";
  $man_fh->seek(0, 0);
  open STDIN, "<&=", $man_fh;
  my $html = slurp '-|', @mandoc;
  my $body = join "\n",
    "<!-- begin mandoc -->",
    $self->mandoc_html($c, $html),
    "<!-- end mandoc -->",
    '';

  $self->{body} = $body;
}

use HTML::Spacing::JA;

sub mandoc_html {
  my ($self, $c, $html) = @_;

  my $root = HTML::TreeBuilder->new;
  $root->parse($html);
  my ($body) = grep { ref && $_->tag eq 'body' } $root->content_list;

  # remove header and footer
  for ($body->content_list) {
    if (ref && $_->tag eq 'table' && $_->attr('class') =~ /^(head|foot)$/) {
      $_->delete;
    }
  }

  for ($body->content_list) {
    if (ref && $_->tag eq 'div' && $_->attr('class') eq 'manual-text') {
      $self->{arrange_mandoc_html} = 0;
      $self->arrange_mandoc_html($c, $_);
    }
  }

  # add TOC to the output of mandoc like the output of perldoc server
  # Pod::POM::View::HTML.
  my $index = HTML::TreeBuilder->new;
  $index->parse($self->index);
  my ($index_body) = grep { ref && $_->tag eq 'body' } $index->content_list;
  $body->splice_content(0, 0, $index_body->content_list);
  join "\n", map $_->as_HTML, $body->content_list;
}


if (0) { no warnings 'redefine';
  *HTML::Entities::num_entity = sub { $_[0] };
}


sub arrange_mandoc_html {
  my ($self, $c, $parent) = @_;

  my @chunk;
  for ($parent->detach_content, undef) {
    my $flush;
    if (!defined) {
      $flush = 1;
    } elsif (ref && $_->tag eq 'pre') {
      my @content = split /\n/, $_->as_text;
      s/^\p{blank}+|\p{blank}+$//g for @content;
      $_->detach_content();
      $_->push_content(join "\n", grep /./, @content);
      my %seen;
      $_->attr('class', join ' ', grep !$seen{$_}++, $_->attr('class'), 'verbatim');
      $flush = 1;
    } elsif (ref) {
      $self->{arrange_mandoc_html}++;
      $self->arrange_mandoc_html($c, $_);
      --$self->{arrange_mandoc_html};
      if ($_->tag =~ /^h\d/) {
        if ($_->attr('id')) {
          my $link = HTML::Element->new('a', href => "#".$_->attr('id'));
          $link->push_content($_->as_text);
          if ($_->tag =~ /^h([12])\b/) {
            push @{$self->{index} ||= []}, [ $1, $link->as_HTML ];
          }
        }
        $flush = 1;
      } elsif ($_->tag eq 'br') {
        $flush = 1;
        $_ = undef;
      } elsif ($_->tag eq 'div') {
        $flush = 1;
        if ($_->as_text =~ /^\p{blank}*$/) {
          $_->detach_content;
          $_ = undef;
        }
      } elsif ($_->tag eq 'dl') {
        $flush = 1;
      } elsif ($_->tag eq 'dd') {
        $self->mandoc_link($c, $_);
        push @chunk, $self->mandoc_textblock($c, $_);
      } else {
        push @chunk, $_;
      }
    } else {
      push @chunk, $_;
    }

    if ($flush) {
      if (grep ref || /\S/, @chunk) {
        my $chunk = HTML::Element->new('p');
        $chunk->push_content(@chunk);
        if ($self->{arrange_mandoc_html} == 0) {
          $self->mandoc_link($c, $chunk);
          $parent->push_content($self->mandoc_textblock($c, $chunk));
        } else {
          $self->mandoc_link($c, $chunk);
          $parent->push_content($chunk->detach_content);
        }
      }
      @chunk = ();
      if (defined) {
        $parent->push_content($_);
      }
    }
  }
}


sub mandoc_link {
  my ($self, $c, $parent) = @_;

  return unless ref $parent;
  return unless $parent->can('content_list');
  return if $parent->tag eq 'a';

  my $pindex = 0;
  for ($parent->content_list) {

    # Link something that looks like a manpage. name(sect)
    if (defined && !ref) {
      while (/\b(\w[\w\.\-]*?)\((\d+\w*?)\)/g) {
        my ($name, $sect) = ($1, $2);
        (my $regex = "$name($sect)") =~ s/([\/\.\-\(\)\$])/\\$1/g;
        my ($l, $r) = split /$regex/, $_, 2;
        my $manpage = HTML::Element->new(
          'a', href => $c->uri_for("/view/$name($sect)"),
        );
        $manpage->push_content([ 'b', "$name" ], "($sect)");
        my @replace = (
          $l && length($l) > 0 ? ($l) : (),
          $manpage,
          $r && length($r) > 0 ? ($r) : (),
        );
        $parent->splice_content($pindex, 1, @replace);
        $pindex += @replace - 1;
        $_ = $r;
      }
    }

    # Similar to above. <b>name</b>(sect)
    if (defined && !ref) {
      if (/^\((\d+\w*?)\)(.*)/) {
        my ($sect, $r) = ($1, $2);
        my $p = $pindex > 0 ? $parent->content->[$pindex - 1] : undef;
        if (ref $p && $p->tag =~ /^(b|i)$/ && $p->as_text =~ /(\w[\w\.\-]*)$/) {
          my $name = $1;
          my $manpage = HTML::Element->new(
            'a', href => $c->uri_for("/view/$name($sect)"),
          );
          $manpage->push_content([ $p->tag, "$name" ], "($sect)");
          my @replace = (
            $manpage,
            $r && length($r) > 0 ? ($r) : (),
          );
          $parent->splice_content($pindex - 1, 2, @replace);
          $pindex += @replace - 2;
          $_ = $r;
        }
      }
    }

    # Link something that looks like a uri.
    if (defined && !ref && $parent->tag ne 'pre') {
      my $regex = qr/(?:http|ftp)s?:\/\/[-_.!~*\'\(\)a-zA-Z0-9;\/?:@&=+\$,%\#]+/;
      while (/\b$regex/g) {
        my ($uri) = ($&);
        my ($l, $r) = split /$regex/, $_, 2;
        my $manpage = HTML::Element->new('a', href => $uri);
        $manpage->push_content($uri);
        my @replace = (
          $l && length($l) > 0 ? ($l) : (),
          $manpage,
          $r && length($r) > 0 ? ($r) : (),
        );
        $parent->splice_content($pindex, 1, @replace);
        $pindex += @replace - 1;
        $_ = $r;
      }
    }

    $pindex++;
  }

}


sub mandoc_textblock {
  my ($self, $c, $text) = @_;
  my $lang = $c->stash->{lang} // '';
  if ($lang && uc($lang) eq 'JA') {
    my $ja = HTML::Spacing::JA->new(
      output_tag => '.',
      #verbose => 1,
      #punct_spacing => -1,
    );
    if ($ja) {
      $ja->arrange($text);
    }
  }
  $text;
}

sub body {
  my $self = shift;
  $self->{body};
}

sub index {
  my $self = shift;
  my $index = $self->{index};
  if ($index && @$index) {
    my @html;
    my $lastlev = 0;
    for (@$index) {
      my ($lev, $html) = @$_;
      push @html, ("<ul>" ) x ($lev - $lastlev) if $lev > $lastlev;
      push @html, ("</ul>") x ($lastlev - $lev) if $lev < $lastlev;
      push @html, "<li>", $html;
      $lastlev = $lev;
    }
    push @html, ("</ul>") x ($lastlev - 0);
    join "\n", @html;
  } else {
    '';
  }
}

1;

__END__

=head1 NAME

Perldoc::Server::Convert::Mandoc - manpage converter

=head1 DESCRIPTION

Use L<mandoc(1)> to create HTML from manpages.

=head1 AUTHOR

Kubo, Koichi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
