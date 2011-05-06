#!/usr/bin/perl -w

use strict;

use Test::More; # tests => 2;

use IO::Handle;
use Term::TermKey;


pipe(my ($rd, $wr)) or die "Cannot pipe() - $!";

# Sanitise this just in case
#$ENV{TERM} = "vt100";

my $tk = new_ok('Term::TermKey', [$rd, 0]);

my $key;

# # ensure perl and libtermkey agree on Unicode handling
#binmode($wr, ":encoding(UTF-8)") if $tk->get_flags & FLAG_UTF8;
# #binmode($rd, ":encoding(UTF-8)") if $tk->get_flags & FLAG_UTF8;

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE when empty' );

ok( defined $key, '$key is defined' );

$wr->autoflush(1);
$wr->syswrite("\eOQ", 4);# send an F2 key.

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE before advisereadable' );

$tk->advisereadable;

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after pipe write' );

is( $key->termkey, $tk,           '$key->termkey retrieved ok' );

is( $key->type, TYPE_FUNCTION,    '$key->type_is_function' );
is( $key->utf8, undef,           '$key->utf8 isn\'t buggered');

diag ("Type: " . $key->type);
is( $key->number, 2,            'F1 $key->number' );
is( $key->modifiers, 0,         'no $key->modifiers' );

done_testing;







# while((my $ret = $tk->getkey(my $key)) != RES_EOF) {
#     if ($key->type_is_function) {
#         my $val = $key->utf8;
#         is($val, undef, 'fetching ->utf8 no longer causes a segfault');
#         last;
#     }
# }

