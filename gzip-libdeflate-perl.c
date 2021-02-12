typedef struct {
    struct libdeflate_compressor * c;
    struct libdeflate_decompressor * d;
}
gzip_libdeflate_t;

static SV *
set_up_out (SV * out, size_t r)
{
    if (r == 0) {
	warn ("compression failed, not enough room");
	return &PL_sv_undef;
    }
    SvPOK_on (out);
    SvCUR_set(out, (STRLEN) r);
    return out;
}

static SV *
gzip_libdeflate_deflate_compress (gzip_libdeflate_t * gl, SV * in_sv)
{
    const char * in;
    STRLEN in_len;
    size_t out_nbytes;
    size_t r;
    SV * out;
    char * out_p;

    in = SvPV (in_sv, in_len);
    out_nbytes = libdeflate_deflate_compress_bound (gl->c, in_len);
    out = newSV (out_nbytes);
    out_p = SvPVX (out);
    r = libdeflate_deflate_compress (gl->c, in, (size_t) in_len,
				     out_p, out_nbytes);
    return set_up_out (out, r);
}

static SV *
gzip_libdeflate_zlib_compress (gzip_libdeflate_t * gl, SV * in_sv)
{
    const char * in;
    STRLEN in_len;
    size_t out_nbytes;
    size_t r;
    SV * out;
    char * out_p;

    in = SvPV (in_sv, in_len);
    out_nbytes = libdeflate_zlib_compress_bound (gl->c, in_len);
    out = newSV (out_nbytes);
    out_p = SvPVX (out);
    r = libdeflate_zlib_compress (gl->c, in, (size_t) in_len,
				  out_p, out_nbytes);
    return set_up_out (out, r);
}

static SV *
gzip_libdeflate_gzip_compress (gzip_libdeflate_t * gl, SV * in_sv)
{
    const char * in;
    STRLEN in_len;
    size_t out_nbytes;
    size_t r;
    SV * out;
    char * out_p;

    in = SvPV (in_sv, in_len);
    out_nbytes = libdeflate_gzip_compress_bound (gl->c, in_len);
    out = newSV (out_nbytes);
    out_p = SvPVX (out);
    r = libdeflate_gzip_compress (gl->c, in, (size_t) in_len,
				  out_p, out_nbytes);
    return set_up_out (out, r);
}

static SV *
gzip_libdeflate_deflate_decompress (gzip_libdeflate_t * gl, SV * in_sv)
{
    return &PL_sv_undef;
}

static SV *
gzip_libdeflate_zlib_decompress (gzip_libdeflate_t * gl, SV * in_sv)
{
    return &PL_sv_undef;
}

/* https://github.com/ebiggers/libdeflate/blob/master/programs/gzip.c#L177 */

static u32
load_u32_gzip(const u8 *p)
{
	return
	    ((u32)p[0] << 0) |
	    ((u32)p[1] << 8) |
	    ((u32)p[2] << 16) |
	    ((u32)p[3] << 24);
}

static SV *
gzip_libdeflate_gzip_decompress (gzip_libdeflate_t * gl, SV * in_sv)
{
    const char * in;
    STRLEN in_len;
    size_t out_nbytes;
    size_t r;
    SV * out;
    char * out_p;

    in = SvPV (in_sv, in_len);
    r = load_u32_gzip((u8*)(&in[in_len - 4]));
    if (r == 0) {
	r = 1;
    }
    out = newSV (r);
    out_p = SvPVX (out);
    do {
    size_t n;
    size_t o;
	enum libdeflate_result result;
	result = libdeflate_gzip_decompress_ex (gl->d,
						in, in_len,
						out_p, r,
						& n, & o);
	if (result != LIBDEFLATE_SUCCESS) {
	    warn ("Decompress failed with error %d", result);
	    return &PL_sv_undef;
	}
    }
    while (0);
    return set_up_out (out, r);
}
