#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "gzip-libdeflate-perl.c"

typedef gzip_libdeflate_t * Gzip__Libdeflate;

MODULE=Gzip::Libdeflate PACKAGE=Gzip::Libdeflate

PROTOTYPES: DISABLE

BOOT:
	/* Gzip__Libdeflate_error_handler = perl_error_handler; */

