package Perldoc::Server::Model::Man;

use strict;
use warnings;
use 5.010;
use parent 'Catalyst::Model';

use Perl6::Slurp qw/slurp/;
use utf8;

sub ACCEPT_CONTEXT { 
  my ( $self, $c, @extra_arguments ) = @_; 
  bless { %$self, c => $c }, ref($self); 
}

sub find {
  my ($self, @man) = @_;
  if (@man) {
    my $lang = $self->lang_default;
    my ($section, $topic);
    if (@man == 2) {
      ($section, $topic) = @man;
    } elsif (@man == 1) {
      if ($man[0] =~ /([^\(]+)\(([^\)]+)\)/) {
        ($section, $topic) = ($2, $1);
      } else {
        $topic = $_[0];
      }
    }
    return () unless $topic;
    my @man_w = qw/man -w/;
    push @man_w, "-L".$lang if $lang;
    push @man_w, $section if $section;
    push @man_w, $topic;
    chop(my $filename = `@man_w`);
    warn "# filename = $filename\n"; # xxxxx
    $section ||= $1 if $filename =~ m{/man(\w+)/$topic};
    $section ||= $1 if $filename =~ m{/$topic\.(\w+)(\.gz)?$};
    $self->{section} = $section;
    $self->{topic} = $topic;
    if ($filename =~ m{/$lang/man(\w+)/$topic}) {
      $self->{lang} = $lang;
    }
    return $filename;
  }
  return ();
}

sub man {
  my ($self, @man) = @_;
  if (my $file = $self->find(@man)) {
    my $cat = $file =~ /gz$/? 'zcat' : 'cat';
    my $man = slurp "-|:encoding(utf8)", $cat, $file;
    unless ($self->{lang}) {
      my $lang;
      my $cc = "[.']";
      if (my $lang_hint = $self->lang_hint) {
      get_lang:
        while ($man =~ /^($cc\s*S[Hh])\s+(.*?)\s*$/gm) {
          my $word = $2;
          while (my ($lang, $hint) = each %$lang_hint) {
            $self->{lang} = $lang, last get_lang if $word =~ /^(?:$hint)$/;
          }
        }
      }
    }
    if ($self->{lang}) {
      for (grep $self->can($_), "$self->{lang}_subr") {
        if (my $prefer = $self->$_($man)) {
          $man = $prefer;
          last;
        }
      }
    }
    return $man;
  }
  return qq[.SH "Cannot find manpage for @man"];
}

sub lang_hint {
  my ($self) = @_;
  if (my $c = $self->{c}) {
    my $lang_hint = ref $c->config->{lang} && $c->config->{lang}{hint};
    $lang_hint = undef unless ref($lang_hint) eq 'HASH';
    return $lang_hint;
  }
  return undef;
}

sub lang_default {
  my ($self) = @_;
  if (my $c = $self->{c}) {
    my $lang = $c->req->params->{lang} ||
      ref $c->config->{lang} && $c->config->{lang}{default} ||
      $c->config->{lang};
    return $lang;
  }
  return undef;
}

sub lang {
  my ($self, @man) = @_;

  $self->find(@man) if @man;
  $self->{lang};
}

sub ja_subr {
  my ($self, $text) = @_;

  my $ja =
    qr/(?:
         [\x{2E80}-\x{2EFF}]	# CJK Radicals Supplement 	CJK部首補助
       #| [\x{2F00}-\x{2FDF}]	# Kangxi Radicals 		康煕部首
       | [\x{2FF0}-\x{2FFF}]	# Ideographic Description Characters 漢字構成記述文字
       #| [\x{3000}-\x{303F}]	# CJK Symbols and Punctuation	CJKの記号と句読点
       | [\x{3000}\x{3003}-\x{303F}] # \x{3001}: (、) \x{3002}: (。)
       | [\x{3040}-\x{309F}]	# Hiragana 			平仮名
       | [\x{30A0}-\x{30FF}]	# Katakana 			片仮名
       | [\x{31C0}-\x{31EF}]	# CJK Strokes 			CJKの筆画
       | [\x{31F0}-\x{31FF}]	# Katakana Phonetic Extensions 	片仮名拡張
       | [\x{3200}-\x{32FF}]	# Enclosed CJK Letters and Months 囲みCJK文字・月
       | [\x{3300}-\x{33FF}]	# CJK Compatibility 		CJK互換用文字
       | [\x{3400}-\x{4DBF}]	# CJK Unified Ideographs Extension A CJK統合漢字拡張A
       #| [\x{4DC0}-\x{4DFF}]	# Yijing Hexagram Symbols	易経記号
       | [\x{4E00}-\x{9FFC}]	# CJK Unified Ideographs 	CJK統合漢字
       | [\x{F900}-\x{FAFF}]	# CJK Compatibility Ideographs 	CJK互換漢字
       #| [\x{FE10}-\x{FE1F}]	# Vertical Forms 		縦書き形
       #| [\x{FE20}-\x{FE2F}]	# Combining Half Marks		半記号（合成可能）
       #| [\x{FE30}-\x{FE4F}]	# CJK Compatibility Forms	CJK互換形
       #| [\x{FE50}-\x{FE6F}]	# Small Form Variants		小字形
       #| [\x{FF00}-\x{FFEF}]	# Halfwidth and Fullwidth Forms	半角・全角形
       #| [\x{FFF0}-\x{FFFF}]	# Specials			特殊記号
       | [\x{20000}-\x{2A6DD}]	# CJK Unified Ideographs Extension B CJK統合漢字拡張B
       | [\x{2A700}-\x{2B734}]	# CJK Unified Ideographs Extension C CJK統合漢字拡張C
       | [\x{2B740}-\x{2B81D}]	# CJK Unified Ideographs Extension D CJK統合漢字拡張D
       | [\x{2B820}-\x{2CEA1}]	# CJK Unified Ideographs Extension E CJK統合漢字拡張E
       | [\x{2CEB0}-\x{2EBE0}]	# CJK Unified Ideographs Extension F CJK統合漢字拡張F
       | [\x{2F800}-\x{2FA1F}]	# CJK Compatibility Ideographs Supplement CJK互換漢字補助
       # | [\x{2FF80}-\x{2FFFF}] # Unassigned			未割り当て（第2面）
       | [\x{30000}-\x{3134A}]	# CJK Unified Ideographs Extension G CJK統合漢字拡張G
       )/x;

  my $cc = "[.']";
  my $out = '';
  my @out;
  my @t;
  my $NAME_found;
  my @unget = split /\n/, $text;
  while (@unget) {
    local ($_) = shift @unget;
    if (@t) {
      if (/\\$/) {
        push @t, $_;
      } elsif ($t[0] !~ /^$cc/ && $t[-1] =~ /$ja$/ && /^$ja/) {
        $t[-1] .= "\\c";
        push @t, $_;
      } else {
        unshift @unget, $_;
        push @out, @t;
        @t = ();
      }
    } elsif (!/^$cc/ || /\\$/) {
      push @t, $_;
    } else {
      push @out, $_;
    }
  }
  $out .= "$_\n" for @out, @t;
  $out;
}

=head1 NAME

Perldoc::Server::Model::Man - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

B<NOTE:> Detects language of the manpage and executes the
language-specific subroutine I<lang>_subr (), if defined.  The method
of detecting the language is almost the same as
L<Perldoc::Server::Model::Pod>.

I<lang>_subr() is an experimental subroutine that allows you to place
language-specific processing.  For example, Japanese usually doesn't
use word-separation. It's different from other languages. In Japanese,
when a sentence continues from the end of a line to the beginning of
the next line, it is better to put C<\c> at the end of the line to
disable the line break.

=head1 AUTHOR

Koichi Kubo

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
