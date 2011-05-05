#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say switch/;

use Term::TermKey;

my $tk = Term::TermKey->new(\*STDIN);

binmode(STDOUT, ":encoding(UTF-8)")
  if $tk->get_flags & FLAG_UTF8;

my $key;
while((my $ret = $tk->waitkey($key)) != RES_EOF) {

    say "Got key: " . $tk->format_key($key, FORMAT_VIM);
}
