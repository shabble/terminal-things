package Term::TermKey;

use strict;
use warnings;

our $VERSION = '0.06';

use base qw( DynaLoader );
use base qw( Exporter );

__PACKAGE__->DynaLoader::bootstrap( $VERSION );

=head1 NAME

C<Term::TermKey> - perl wrapper around C<libtermkey>

=head1 SYNOPSIS

 use Term::TermKey;

 my $tk = Term::TermKey->new( \*STDIN );

 print "Press any key\n";

 $tk->waitkey( my $key );

 print "You pressed: " . $tk->format_key( $key, 0 );

=head1 DESCRIPTION

This module provides a light perl wrapper around the C<libtermkey> library.
This library attempts to provide an abstract way to read keypress events in
terminal-based programs by providing structures that describe keys, rather
than simply returning raw bytes as read from the TTY device.

=head2 Multi-byte keys, ambiguous keys, and waittime

Some keypresses generate multiple bytes from the terminal. There is also the
ambiguity between multi-byte CSI or SS3 sequences, and the Escape key itself.
The waittime timer is used to distinguish them.

When some bytes arrive that could be the start of possibly multiple different
keypress events, the library will attempt to wait for more bytes to arrive
that would finish it. If no more bytes arrive after this time, then the bytes
will be reported as events as they stand, even if this results in interpreting
a partially-complete Escape sequence as a literal Escape key followed by some
normal letters or other symbols.

Similarly, if the start of an incomplete UTF-8 sequence arrives when the
library is in UTF-8 mode, this will be reported as the UTF-8 replacement
character (U+FFFD) if it is incomplete after this time.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $tk = Term::TermKey->new( $term, $flags )

Construct a new C<Term::TermKey> object that wraps the given term handle.
C<$term> should be either an IO handle reference or an integer containing a
plain POSIX file descriptor. C<$flags> is optional, but if given, should
contain the flags to pass to C<libtermkey>'s constructor. Assumes a default
of 0 if not supplied. See the C<FLAG_*> constants.

=cut

=head1 METHODS

=cut

# The following documents the various XS-implemented methods in TermKey.xs in
# the same order

=head2 $flags = $tk->get_flags

Return the current flags in operation, as specified in the constructor or the
last call to C<set_flags()>. One of the C<FLAG_UTF8> or C<FLAG_RAW> flags will
be set, even if neither was present in the constructor, as in this case the
library will attempt to detect if the current locale is UTF-8 aware or not.

=cut

=head2 $tk->set_flags( $newflags )

Set the flags. This is a bitmask the same as the value passed to the
constructor.

=cut

=head2 $msec = $tk->get_waittime

Return the current maximum wait time in miliseconds as set by the
C<set_waittime()> method. The underlying C<libtermkey> library will have
specified a default value when it started.

=cut

=head2 $tk->set_waittime( $msec )

Set the maximum wait time in miliseconds to await more of a partially complete
key sequence.

=cut

=head2 $res = $tk->getkey( $key )

Attempt to retrieve a single keypress event from the buffer, and put it in
C<$key>. If successful, will return C<RES_KEY> to indicate that the C<$key>
structure now contains a new keypress event. If C<$key> is an undefined lvalue
(such as a new scalar variable) it will be initialised to contain a new key
structure.

If nothing is in the buffer it will return C<RES_NONE>. If the buffer contains
a partial keypress event which does not yet contain all the bytes required, it
will return C<RES_AGAIN> (see above section about multibyte events). If no
events are ready and the input stream is now closed, will return C<RES_EOF>.

This method will not block, nor will it perform any IO on the underlying file
descriptor. For a normal blocking read, see C<waitkey()>.

=cut

=head2 $res = $tk->getkey_force( $key )

Similar to C<getkey()>, but will not return C<RES_AGAIN> if a partial match
was found. Instead, it will force an interpretation of the bytes, even if this
means interpreting the start of an C<< <Esc> >>-prefixed multibyte sequence as
a literal C<Escape> key followed by normal letters. If C<$key> is an undefined
lvalue (such as a new scalar variable) it will be initialised to contain a new
key structure.

This method will not block, nor will it perform any IO on the underlying file
descriptor. For a normal blocking read, see C<waitkey()>.

=cut

=head2 $res = $tk->waitkey( $key )

Attempt to retrieve a single keypress event from the buffer, or block until
one is available. If successful, will return C<RES_KEY> to indicate that the
C<$key> structure now contains a new keypress event. The only other result it
can return is C<RES_EOF>, to indicate that the input stream is now closed. If
C<$key> is an undefined lvalue (such as a new scalar variable) it will be
initialised to contain a new key structure.

=cut

=head2 $res = $tk->advisereadable

Inform the underlying library that new input may be available on the
underlying file descriptor and so it should call C<read()> to obtain it.
Will return C<RES_AGAIN> if it read at least one more byte, or C<RES_NONE> if
no more input was found.

Normally this method would only be used in programs that want to use
C<Term::TermKey> asynchronously; see the EXAMPLES section. This method
gracefully handles an C<EAGAIN> error from the underlying C<read()> syscall.

=cut

=head2 $str = $tk->get_keyname( $sym )

Returns the name of a key sym, such as returned by
C<< Term::TermKey::Key->sym() >>.

=cut

=head2 $sym = $tk->keyname2sym( $keyname )

Look up the sym for a named key. The result of this method call can be
compared directly against the value returned by
C<< Term::TermKey::Key->sym() >>. Because this method has to perform a linear
search of key names, it is best called rarely, perhaps during program
initialisation, and the result stored for easier comparisons during runtime.

=cut

=head2 ( $ev, $button, $line, $col ) = $tk->interpret_mouse( $key )

If C<$key> contains a mouse event then its details are returned in a list.
C<$ev> will be one of the C<TERMKEY_MOUSE_*> constants, C<$button> will be the
button number it relates to, and C<$line> and C<$col> will give the screen
coordinates, numbered from 1. If C<$key> does not contain a mouse event then
an empty list is returned.

=cut

=head2 $str = $tk->format_key( $key, $format )

Return a string representation of the keypress event in C<$key>, following the
flags given. See the descriptions of the flags, below, for more detail.

This may be useful for matching keypress events against keybindings stored in
a hash. See EXAMPLES section for more detail.

=cut

=head1 KEY OBJECTS

The C<Term::TermKey::Key> subclass is used to store a single keypress event.
Objects in this class cannot be changed by perl code. C<getkey()>,
C<getkey_force()> or C<waitkey()> will overwrite the contents of the structure
with a new value.

=head2 $key = Term::TermKey::Key->new

Construct a new blank key event structure.

=head2 $key->type

The type of event. One of C<TYPE_UNICODE>, C<TYPE_FUNCTION>, C<TYPE_KEYSYM>,
C<TYPE_MOUSE>.

=head2 $key->type_is_unicode

=head2 $key->type_is_function

=head2 $key->type_is_keysym

=head2 $key->type_is_mouse

Shortcuts which return a boolean.

In the case of a mouse event, you must use the C<interpret_mouse> method on
the containing C<Term::TermKey> object to access the event details.

=head2 $key->codepoint

The Unicode codepoint number for C<TYPE_UNICODE>, or 0 otherwise.

=head2 $key->number

The function key number for C<TYPE_FUNCTION>, or 0 otherwise.

=head2 $key->sym

The key symbol number for C<TYPE_KEYSYM>, or 0 otherwise. This can be passed
to C<< Term::TermKey->get_keyname() >>, or compared to a result earlier
obtained from C<< Term::TermKey->keyname2sym() >>.

=head2 $key->modifiers

The modifier bitmask. Can be compared against the C<KEYMOD_*> constants.

=head2 $key->utf8

A string representation of the given Unicode codepoint. If the underlying
C<termkey> library is in UTF-8 mode then this will be a UTF-8 string. If it is
in raw mode, then this will be a single raw byte.

=head2 $key->termkey

Return the underlying C<Term::TermKey> object this key was retrieved from.

=head2 $str = $key->format( $format )

Returns a string representation of the keypress event, identically to calling
C<format_key> on the underlying C<Term::TermKey> object.

=cut

sub Term::TermKey::Key::format
{
   my $self = shift;
   return $self->termkey->format_key( $self, @_ );
}

=head1 EXPORTED CONSTANTS

The following constant names are all derived from the underlying C<libtermkey>
library. For more detail see the documentation on the library.

These constants are possible values of C<< $key->type >>

=over 4

=item C<TYPE_UNICODE>

a Unicode codepoint

=item C<TYPE_FUNCTION>

a numbered function key

=item C<TYPE_KEYSYM>

a symbolic key

=item C<TYPE_MOUSE>

a mouse movement or button press or release

=back

These constants are result values from C<getkey()>, C<getkey_force()>,
C<waitkey()> or C<advisereadable()>

=over 4

=item C<RES_NONE>

No key event is ready.

=item C<RES_KEY>

A key event has been provided.

=item C<RES_EOF>

No key events are ready and the terminal has been closed, so no more will
arrive.

=item C<RES_AGAIN>

No key event is ready yet, but a partial one has been found. This is only
returned by C<getkey()>. To obtain the partial result even if it never
completes, call C<getkey_force()>.

=back

These constants are key modifier masks for C<< $key->modifiers >>

=over 4

=item C<KEYMOD_SHIFT>

=item C<KEYMOD_ALT>

=item C<KEYMOD_CTRL>

Should be obvious ;)

=back

These constants are types of mouse event which may be returned by
C<interpret_mouse>:

=over 4

=item C<TERMKEY_MOUSE_UNKNOWN>

The type of mouse event was not recognised

=item C<TERMKEY_MOUSE_PRESS>

The event reports a mouse button being pressed

=item C<TERMKEY_MOUSE_DRAG>

The event reports the mouse being moved while a button is held down

=item C<TERMKEY_MOUSE_RELEASE>

The event reports the mouse buttons being released, or the mouse moved without
a button held.

=back

These constants are flags for the constructor, C<< Term::TermKey->new >>

=over 4

=item C<FLAG_NOINTERPRET>

Do not attempt to interpret C0 codes into keysyms (ie. C<Backspace>, C<Tab>,
C<Enter>, C<Escape>). Instead report them as plain C<Ctrl-letter> events.

=item C<FLAG_CONVERTKP>

Convert xterm's alternate keypad symbols into the plain ASCII codes they would
represent.

=item C<FLAG_RAW>

Ignore locale settings; do not attempt to recombine UTF-8 sequences. Instead
report only raw values.

=item C<FLAG_UTF8>

Ignore locale settings; force UTF-8 recombining on.

=item C<FLAG_NOTERMIOS>

Even if the terminal file descriptor represents a TTY device, do not call the
C<tcsetattr()> C<termios> function on it to set in canonical input mode.

=back

These constants are flags to C<format_key>

=over 4

=item C<FORMAT_LONGMOD>

Print full modifier names e.g. C<Shift-> instead of abbreviating to C<S->.

=item C<FORMAT_CARETCTRL>

If the only modifier is C<Ctrl> on a plain character, render it as C<^X>.

=item C<FORMAT_ALTISMETA>

Use the name C<Meta> or the letter C<M> instead of C<Alt> or C<A>.

=item C<FORMAT_WRAPBRACKET>

If the key event is a special key instead of unmodified Unicode, wrap it in
C<< <brackets> >>.

=item C<FORMAT_MOUSE_POS>

If the event is a mouse event, also include the cursor position; rendered as
C<@ ($col,$line)>

=item C<FORMAT_VIM>

Shortcut to C<FORMAT_ALTISMETA|FORMAT_WRAPBRACKET>; which gives an output
close to the format the F<vim> editor uses.

=back

=cut

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 EXAMPLES

=head2 A simple print-until-C<Ctrl-C> loop

This program just prints every keypress until the user presses C<Ctrl-C>.

 use Term::TermKey qw( FLAG_UTF8 RES_EOF KEYMOD_CTRL FORMAT_VIM );
 
 my $tk = Term::TermKey->new(\*STDIN);
 
 # ensure perl and libtermkey agree on Unicode handling
 binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;
 
 while( ( my $ret = $tk->waitkey( my $key ) ) != RES_EOF ) {
    print "Got key: ".$tk->format_key( $key, FORMAT_VIM )."\n";

    last if $key->type_is_unicode and 
            lc $key->utf8 eq "c" and
            $key->modifiers & KEYMOD_CTRL;
 }

=head2 Configuration of custom keypresses

Because C<format_key()> yields a plain string representation of a keypress it
can be used as a hash key to look up a "handler" routine for the key.

The following implements a simple line input program, though obviously lacking
many features in a true line editor like F<readline>.

 use Term::TermKey qw( FLAG_UTF8 RES_EOF FORMAT_LONGMOD );
 
 my $tk = Term::TermKey->new(\*STDIN);
 
 # ensure perl and libtermkey agree on Unicode handling
 binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;

 my $line = "";

 $| = 1;

 my %key_handlers = (
    "Ctrl-c" => sub { exit 0 },

    "Enter"  => sub { 
       print "\nThe line is: $line\n";
       $line = "";
    },

    "Backspace" => sub {
       return unless length $line;
       substr( $line, -1, 1 ) = "";
       print "\cH \cH"; # erase it
    },

    "Space" => sub {
       $line .= " ";
       print " ";
    },

    # other handlers ...
 );
 
 while( ( my $ret = $tk->waitkey( my $key ) ) != RES_EOF ) {
    my $handler = $key_handlers{ $tk->format_key( $key, FORMAT_LONGMOD ) };
    if( $handler ) {
       $handler->( $key );
    }
    elsif( $key->type_is_unicode and !$key->modifiers ) {
       my $char = $key->utf8;

       $line .= $char;
       print $char;
    }
 }

=head2 Asynchronous operation

Because the C<getkey()> method performs no IO itself, it can be combined with
the C<advisereadable()> method in an asynchronous program.

 use IO::Select;
 use Term::TermKey qw(
    FLAG_UTF8 KEYMOD_CTRL RES_KEY RES_AGAIN RES_EOF FORMAT_VIM
 );
 
 my $select = IO::Select->new();
 
 my $tk = Term::TermKey->new(\*STDIN);
 $select->add(\*STDIN);
 
 # ensure perl and libtermkey agree on Unicode handling
 binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;
 
 sub on_key
 {
    my ( $tk, $key ) = @_;
 
    print "You pressed " . $tk->format_key( $key, FORMAT_VIM ) . "\n";
 
    exit if $key->type_is_unicode and
            lc $key->utf8 eq "c" and
            $key->modifiers & KEYMOD_CTRL;
 }
 
 my $again = 0;
 
 while(1) {
    my $timeout = $again ? $tk->get_waittime/1000 : undef;
    my @ready = $select->can_read($timeout);
 
    if( !@ready ) {
       my $ret;
       while( ( $ret = $tk->getkey_force( my $key ) ) == RES_KEY ) {
          on_key( $tk, $key );
       }
    }
 
    while( my $fh = shift @ready ) {
       if( $fh == \*STDIN ) {
          $tk->advisereadable;
          my $ret;
          while( ( $ret = $tk->getkey( my $key ) ) == RES_KEY ) {
             on_key( $tk, $key );
          }
 
          $again = ( $ret == RES_AGAIN );
          exit if $ret == RES_EOF;
       }
       # Deal with other filehandles here
    }
 }

See also the L<Term::TermKey::Async> module which provides a convenient
wrapping of C<Term::TermKey> for an L<IO::Async>-based program.

=cut

=head1 TODO

=over 4

=item *

Consider if C<< $key = $tk->waitkey >> is a better API. While underlying
library only returns C<RES_KEY> or C<RES_NONE> that works but if it ever gains
another value, all bets are off. Return undef and have a C<< ->err >> method?
Going into messyland...

=back

=head1 SEE ALSO

=over 4

=item *

L<http://www.leonerd.org.uk/code/libtermkey/> - libtermkey home page

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

