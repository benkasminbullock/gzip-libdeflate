#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* The following macros clash with ones from Perl. */

#undef MIN
#undef MAX
#undef ALIGN

#include "libdeflate.c"
#include "gzip-libdeflate-perl.c"

typedef gzip_libdeflate_t * Gzip__Libdeflate;

MODULE=Gzip::Libdeflate PACKAGE=Gzip::Libdeflate

PROTOTYPES: DISABLE

Gzip::Libdeflate
compressor (class, level = 6)
	const char * class;
	int level;
CODE:
	Newxz (RETVAL, 1, gzip_libdeflate_t);
	RETVAL->c = libdeflate_alloc_compressor(level);
OUTPUT:
	RETVAL

Gzip::Libdeflate
decompressor (class)
	const char * class;
CODE:
	Newxz (RETVAL, 1, gzip_libdeflate_t);
	RETVAL->d = libdeflate_alloc_decompressor ();
OUTPUT:
	RETVAL

SV *
deflate_compress (gl, in)
	Gzip::Libdeflate gl;
	SV * in;
CODE:
	RETVAL = gzip_libdeflate_deflate_compress (gl, in);
OUTPUT:
	RETVAL

SV *
zlib_compress (gl, in)
	Gzip::Libdeflate gl;
	SV * in;
CODE:
	RETVAL = gzip_libdeflate_zlib_compress (gl, in);
OUTPUT:
	RETVAL

SV *
gzip_compress (gl, in)
	Gzip::Libdeflate gl;
	SV * in;
CODE:
	RETVAL = gzip_libdeflate_gzip_compress (gl, in);
OUTPUT:
	RETVAL

SV *
deflate_decompress (gl, in)
	Gzip::Libdeflate gl;
	SV * in;
CODE:
	RETVAL = gzip_libdeflate_deflate_decompress (gl, in);
OUTPUT:
	RETVAL

SV *
zlib_decompress (gl, in)
	Gzip::Libdeflate gl;
	SV * in;
CODE:
	RETVAL = gzip_libdeflate_zlib_decompress (gl, in);
OUTPUT:
	RETVAL

SV *
gzip_decompress (gl, in)
	Gzip::Libdeflate gl;
	SV * in;
CODE:
	RETVAL = gzip_libdeflate_gzip_decompress (gl, in);
OUTPUT:
	RETVAL


void
DESTROY (gl)
	Gzip::Libdeflate gl;
CODE:
	if (gl->c) {
		libdeflate_free_compressor (gl->c);
		gl->c = 0;
	}
	if (gl->d) {
		libdeflate_free_decompressor (gl->d);
		gl->d = 0;
	}
