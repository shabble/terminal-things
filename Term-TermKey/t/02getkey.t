#!/usr/bin/perl

use strict;

use Test::More tests => 27;
use Test::Refcount;

use IO::Handle;

use Term::TermKey;

pipe( my ( $rd, $wr ) ) or die "Cannot pipe() - $!";

# Sanitise this just in case
$ENV{TERM} = "vt100";

my $tk = Term::TermKey->new( $rd, 0 );

is_oneref( $tk, '$tk has refcount 1 initially' );

my $key;

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE when empty' );

ok( defined $key, '$key is defined' );

is_oneref( $key, '$key has refcount 1 after getkey()' );
is_refcount( $tk, 2, '$tk has refcount 2 after getkey()' );

$wr->syswrite( "h" );

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE before advisereadable' );

$tk->advisereadable;

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after h' );

is( $key->termkey, $tk, '$key->termkey after h' );

ok( $key->type_is_unicode,     '$key->type_is_unicode after h' );
is( $key->codepoint, ord("h"), '$key->codepoint after h' );
is( $key->modifiers, 0,        '$key->modifiers after h' );

is( $key->utf8, "h", '$key->utf8 after h' );

is( $key->format( 0 ), "h", '$key->format after h' );

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE a second time' );

$wr->syswrite( "\cA" );

$tk->advisereadable;

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after C-a' );

ok( $key->type_is_unicode,        '$key->type_is_unicode after C-a' );
is( $key->codepoint, ord("a"),    '$key->codepoint after C-a' );
is( $key->modifiers, KEYMOD_CTRL, '$key->modifiers after C-a' );

is( $key->format( 0 ), "C-a", '$key->format after C-a' );

$wr->syswrite("\e[OQ"); # send F1

$tk->advisereadable;

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after F1' );

ok( $key->type_is_function,       '$key->type_is_function after F1a' );
is( $key->number,    1,           '$key->number is 1  after F1' );
is( $key->modifiers, KEYMOD_CTRL, '$key->modifiers after F1' );

#is( $key->format( 0 ), "C-a", '$key->format after C-a' );


$wr->syswrite( "\eOA" );

$tk->advisereadable;

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after Up' );

ok( $key->type_is_keysym,              '$key->type_is_keysym after Up' );
is( $key->sym, $tk->keyname2sym("Up"), '$key->keysym after Up' );
is( $key->modifiers, 0,                '$key->modifiers after Up' );

is( $key->format( 0 ), "Up", '$key->format after Up' );

is_oneref( $key, '$key has refcount 1 before dropping' );
is_refcount( $tk, 2, '$tk has refcount 2 before dropping key' );

undef $key;

is_oneref( $tk, '$k has refcount 1 before EOF' );
