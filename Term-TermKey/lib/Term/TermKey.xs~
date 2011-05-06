#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <termkey.h>

typedef struct key_extended {
  TermKeyKey k;
  SV        *termkey;
} *Term__TermKey__Key;

typedef TermKey *Term__TermKey;

static void setup_constants(void)
{
  HV *stash;
  AV *export;

  stash = gv_stashpvn("Term::TermKey", 13, TRUE);
  export = get_av("Term::TermKey::EXPORT", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c+8, newSViv(c)); \
  av_push(export, newSVpv(#c+8, 0));

  DO_CONSTANT(TERMKEY_TYPE_UNICODE)
  DO_CONSTANT(TERMKEY_TYPE_FUNCTION)
  DO_CONSTANT(TERMKEY_TYPE_KEYSYM)
  DO_CONSTANT(TERMKEY_TYPE_MOUSE)

  DO_CONSTANT(TERMKEY_RES_NONE)
  DO_CONSTANT(TERMKEY_RES_KEY)
  DO_CONSTANT(TERMKEY_RES_EOF)
  DO_CONSTANT(TERMKEY_RES_AGAIN)

  DO_CONSTANT(TERMKEY_KEYMOD_SHIFT)
  DO_CONSTANT(TERMKEY_KEYMOD_ALT)
  DO_CONSTANT(TERMKEY_KEYMOD_CTRL)

  DO_CONSTANT(TERMKEY_MOUSE_UNKNOWN)
  DO_CONSTANT(TERMKEY_MOUSE_PRESS)
  DO_CONSTANT(TERMKEY_MOUSE_DRAG)
  DO_CONSTANT(TERMKEY_MOUSE_RELEASE)

  DO_CONSTANT(TERMKEY_FLAG_NOINTERPRET)
  DO_CONSTANT(TERMKEY_FLAG_CONVERTKP)
  DO_CONSTANT(TERMKEY_FLAG_RAW)
  DO_CONSTANT(TERMKEY_FLAG_UTF8)
  DO_CONSTANT(TERMKEY_FLAG_NOTERMIOS)

  DO_CONSTANT(TERMKEY_FORMAT_LONGMOD)
  DO_CONSTANT(TERMKEY_FORMAT_CARETCTRL)
  DO_CONSTANT(TERMKEY_FORMAT_ALTISMETA)
  DO_CONSTANT(TERMKEY_FORMAT_WRAPBRACKET)
  DO_CONSTANT(TERMKEY_FORMAT_MOUSE_POS)

  DO_CONSTANT(TERMKEY_FORMAT_VIM)
}

static struct key_extended *get_keystruct_or_new(SV *sv, const char *funcname, SV *termkey)
{
  struct key_extended *key;
  if(sv && !SvOK(sv)) {
    Newx(key, 1, struct key_extended);
    sv_setref_pv(sv, "Term::TermKey::Key", (void*)key);
    key->termkey = NULL;
  }
  else if(sv_derived_from(sv, "Term::TermKey::Key")) {
    IV tmp = SvIV((SV*)SvRV(sv));
    key = INT2PTR(struct key_extended *, tmp);
  }
  else
    Perl_croak(aTHX_ "%s: %s is not of type %s",
                funcname,
                "key", "Term::TermKey::Key");

  if(!key->termkey ||
     SvRV(key->termkey) != SvRV(termkey)) {
    if(key->termkey)
      SvREFCNT_dec(key->termkey);

    key->termkey = newRV_inc(SvRV(termkey));
  }

  return key;
}


MODULE = Term::TermKey::Key  PACKAGE = Term::TermKey::Key    PREFIX = key_

Term::TermKey::Key
new(package)
  char *package
  CODE:
    Newx(RETVAL, 1, struct key_extended);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Term::TermKey::Key self
  CODE:
    SvREFCNT_dec(self->termkey);
    Safefree(self);

int
type(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type;
  OUTPUT:
    RETVAL

int
type_is_unicode(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_UNICODE;
  OUTPUT:
    RETVAL

int
type_is_function(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_FUNCTION;
  OUTPUT:
    RETVAL

int
type_is_keysym(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_KEYSYM;
  OUTPUT:
    RETVAL

int
type_is_mouse(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_MOUSE;
  OUTPUT:
    RETVAL

int
codepoint(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_UNICODE ? self->k.code.codepoint : 0;
  OUTPUT:
    RETVAL

int
number(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_FUNCTION ? self->k.code.number : 0;
  OUTPUT:
    RETVAL

int
sym(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.type == TERMKEY_TYPE_KEYSYM ? self->k.code.sym : TERMKEY_SYM_NONE;
  OUTPUT:
    RETVAL

int
modifiers(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = self->k.modifiers;
  OUTPUT:
    RETVAL

SV *
termkey(self)
  Term::TermKey::Key self
  CODE:
    RETVAL = newRV_inc(SvRV(self->termkey));
  OUTPUT:
    RETVAL

SV *
utf8(self)
  Term::TermKey::Key self
  CODE:
    if(self->k.type == TERMKEY_TYPE_UNICODE) {
      IV tmp;
      TermKey *termkey;

      RETVAL = newSVpv(self->k.utf8, 0);

      tmp = SvIV((SV*)SvRV(self->termkey));
      termkey = INT2PTR(Term__TermKey, tmp);

      if(termkey_get_flags(termkey) & TERMKEY_FLAG_UTF8)
        SvUTF8_on(RETVAL);
    }
    else
      RETVAL = NULL;
  OUTPUT:
    RETVAL


MODULE = Term::TermKey      PACKAGE = Term::TermKey      PREFIX = termkey_

BOOT:
  TERMKEY_CHECK_VERSION;
  setup_constants();

Term::TermKey
new(package, term, flags=0)
  SV *term
  int flags
  INIT:
    int fd;
  CODE:
    if(SvROK(term)) {
      fd = PerlIO_fileno(IoIFP(sv_2io(term)));
    }
    else {
      fd = SvIV(term);
    }
    RETVAL = termkey_new(fd, flags);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Term::TermKey self
  CODE:
    termkey_destroy(self);
  OUTPUT:

int
termkey_get_flags(self)
  Term::TermKey self

void
termkey_set_flags(self, newflags)
  Term::TermKey self
  int newflags

int
termkey_get_waittime(self)
  Term::TermKey self

void
termkey_set_waittime(self, msec)
  Term::TermKey self
  int msec

int
getkey(self, key)
  Term::TermKey self
  Term::TermKey::Key key = NO_INIT
  PREINIT:
    TermKeyResult res;
  PPCODE:
    key = get_keystruct_or_new(ST(1), "Term::TermKey::getkey", ST(0));
    res = termkey_getkey(self, &key->k);
    mPUSHi(res);
    XSRETURN(1);

int
getkey_force(self, key)
  Term::TermKey self
  Term::TermKey::Key key = NO_INIT
  PREINIT:
    TermKeyResult res;
  PPCODE:
    key = get_keystruct_or_new(ST(1), "Termk::TermKey::getkey_force", ST(0));
    res = termkey_getkey_force(self, &key->k);
    mPUSHi(res);
    XSRETURN(1);

void
waitkey(self, key)
  Term::TermKey self
  Term::TermKey::Key key = NO_INIT
  PREINIT:
    TermKeyResult res;
  PPCODE:
    key = get_keystruct_or_new(ST(1), "Term::TermKey::waitkey", ST(0));
    res = termkey_waitkey(self, &key->k);
    mPUSHi(res);
    XSRETURN(1);

int
termkey_advisereadable(self)
  Term::TermKey self

const char *
termkey_get_keyname(self, sym)
  Term::TermKey self
  int sym

int
termkey_keyname2sym(self, keyname)
  Term::TermKey self
  const char *keyname

void
interpret_mouse(self, key)
  Term::TermKey self
  Term::TermKey::Key key
  PREINIT:
    TermKeyMouseEvent ev;
    int button;
    int line, col;
  PPCODE:
    if(termkey_interpret_mouse(self, &key->k, &ev, &button, &line, &col) != TERMKEY_RES_KEY)
      XSRETURN(0);
    mPUSHi(ev);
    mPUSHi(button);
    mPUSHi(line);
    mPUSHi(col);
    XSRETURN(4);

SV *
format_key(self, key, format)
  Term::TermKey self
  Term::TermKey::Key key
  int format
  CODE:
    RETVAL = newSVpvn("", 50);
    SvCUR_set(RETVAL, termkey_snprint_key(self, SvPV_nolen(RETVAL), SvLEN(RETVAL), &key->k, format));
    if(termkey_get_flags(self) & TERMKEY_FLAG_UTF8)
      SvUTF8_on(RETVAL);
  OUTPUT:
    RETVAL
