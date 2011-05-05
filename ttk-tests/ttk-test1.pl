#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say switch/;
use Data::Dumper;

use Term::TermKey;

my $tk = Term::TermKey->new(\*STDIN);

binmode(STDOUT, ":encoding(UTF-8)")
  if $tk->get_flags & FLAG_UTF8;

my $key;
while((my $ret = $tk->waitkey($key)) != RES_EOF) {

    say "Got key: " . $tk->format_key($key, FORMAT_VIM);

    say "Key Details:";

    process_key($key);
    
    say "-" x 30;
}


sub process_key {
    my ($key) = @_;
    my $type = $key->type;

    given ($type) {
        when (TYPE_UNICODE) {
            say "Unicode value is: " . $key->codepoint;
        }
        when (TYPE_FUNCTION) {
            say "F-Key number is: " . $key->number;
        }
        when (TYPE_KEYSYM) {
            say "KeySym is: " . sprintf("0x%04x", $key->sym) .
              " which is " . (Term::TermKey->get_keyname($key->sym));
        }
        when (TYPE_MOUSE) {
            say "Mouse is: magic!";
        }
    }
    say "UTF Value is: " . $key->utf8;

    my $mod = $key->modifiers;

    given ($mod) {
        when (KEYMOD_SHIFT) {
            say "With shift";
        }
        when (KEYMOD_ALT) {
            say "with alt";
        }
        when (KEYMOD_CTRL) {
            say "with ctrl";
       }
    }
}
