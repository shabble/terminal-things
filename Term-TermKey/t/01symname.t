#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

use Term::TermKey;

my $tk = Term::TermKey->new( \*STDIN, 0 );

defined $tk or die "Cannot create termkey instance";

# We know 'Space' ought to exist
my $sym = $tk->keyname2sym( 'Space' );

ok( defined $sym, "defined keyname2sym('Space')" );

is( $tk->get_keyname( $sym ), 'Space', "get_keyname eq Space" );
