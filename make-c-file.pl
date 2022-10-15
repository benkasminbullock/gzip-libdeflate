#!/home/ben/software/install/bin/perl

# Make the single C file from the files

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use File::Slurper qw!read_text write_text!;
use C::Tokenize ':all';
use JSON::Create ':all';
use File::Copy 'copy';

# Turn on or off debugging messages.

#my $verbose = 1;
my $verbose;

# Version of the library

my %version;

my $dir = "$Bin/../../software/libdeflate/libdeflate-1.14";
if (! -d $dir) {
    die "No $dir";
}
my $lib = "$dir/lib";
my $common = "$dir/common";
my @cfiles;
push @cfiles, <$common/*.c>;
push @cfiles, <$lib/*.c>;
push @cfiles, <$lib/arm/*.c>;
push @cfiles, <$lib/x86/*.c>;
my @hfiles;
push @hfiles, <$dir/*.h>;
push @hfiles, <$common/*.h>;
push @hfiles, <$lib/*.h>;
my @x86 = <$lib/x86/*.h>;
for (@x86) {
    s!x86/!x86-!;
}
push @hfiles, @x86;
my @arm = <$lib/arm/*.h>;
for (@arm) {
    s!arm/!arm-!;
}
push @hfiles, @arm;
my %includes;
for my $file (@hfiles) {
    if ($verbose) {
	print "$file\n";
    }
    my $bfile = $file;
    my $hfile = $file;
    $bfile =~ s!.*/!!;
    $hfile =~ s!(x86|arm)-!$1/!g;
    my $text = read_text ($hfile);
    if ($text =~ m!#define\s+(LIBDEFLATE_VERSION_STRING)\s+"(.*?)"!) {
	if ($verbose) {
	    print "Found $1 '$2' in $hfile\n";
	}
	$version{$1} = $2;
    }
    if ($hfile =~ m!(arm|x86)!) {
	my $type = $1;
     	$text =~ s!#\s*include\s*"(.*?)"!#include "$type-$1"!g;
	$text =~ s!$type-\.\./!!;
    }
    $text =~ s!$comment_re!!g;
    $includes{$bfile} = $text;
}
if ($verbose) {
    print "Done files.\n";
}

# Copy the copyright of libdeflate into this directory

copy ("$dir/COPYING", "$Bin/libd-copyr") or die $!;

# The text contents of the output file.

my $c = '';

my $copyright = read_text ("$Bin/libd-copyr");
$c .= "/*\n$copyright\n*/\n";

my $saw_bitbuf_t;

for my $cfile (@cfiles) {
    if (-d $cfile) {
	next;
    }
    my $text = read_text ($cfile);

    $text =~ s!$comment_re!!g;

    if ($cfile =~ m!(arm|x86)!) {
	my $type = $1;
     	$text =~ s!#\s*include\s*"(.*?)"!#include "$type-$1"!g;
	$text =~ s!$type-\.\./!!;
    }
    if ($cfile =~ m!(adler32|crc32)!) {
	my $type = $1;
	$text =~ s!\bdispatch!${type}_dispatch!g;
    }
    if ($cfile =~ m!deflate_((?:de)?compress)!) {
	my $what = uc $1;
	$text =~ s!(BITBUF_NBITS)!${what}_$1!g;
    }

    # http://www.cpantesters.org/cpan/report/648fc304-6d58-11eb-8344-d38a1f24ea8f
    # http://www.cpantesters.org/cpan/report/6ff92c12-6d58-11eb-8344-d38a1f24ea8f
    # http://www.cpantesters.org/cpan/report/6e732488-6d58-11eb-8344-d38a1f24ea8f
    if ($text =~ m!(typedef.*bitbuf_t;)!) {
	if ($saw_bitbuf_t) {
	    $text =~ s!(typedef.*bitbuf_t;)!/* $1 */!g;
	}
	$saw_bitbuf_t = 1;
    }
    $c .= "/* $cfile */\n";
    $c .= $text;
}

while ($c =~ m!
    (
	\#\s*include\s*[<"]
	.*? # Allow for directory paths
	(
	    (?:common_defs
	    |compiler_(?:gcc|msc)
	    |lib_common
	    |libdeflate
	    |(?:arm|x86)-
		(cpu_features
		|crc32_pclmul_template
		    # http://www.cpantesters.org/cpan/report/239faa2c-49ba-11ed-afcc-a473647750dd
		|arm-crc32_pmull_helpers)
	    |(?:x86|arm)/.*?
	    |adler32_vec_template
	    |crc32_vec_template
	    |crc32_table
	    |crc32_tables
	    |crc32_multipliers
	    |deflate_compress
	    |deflate_constants
	    |unaligned
	    |hc_matchfinder
	    |bt_matchfinder
	    |ht_matchfinder
	    |matchfinder_common
	    |decompress_template
	    |gzip_constants
	    |zlib_constants
	    |cpu_features_common
	    )\.h
	)
	[">]
    )!gx) {
    my $include = $1;
    my $hfile = $2;
    $hfile =~ s!(x86|arm)/!$1-!;
    my $nohash = $include;
    # Prevent the commented #include from matching the above big
    # regex.
    $nohash =~ s!#!hashhashhash!;
    if ($includes{$hfile}) {
	# lib/cpu_features_common.h has no include guard so we must
	# not include it twice.
	if ($hfile =~ /cpu_features_common\.h/) {
	    $c =~ s!$include!/* $nohash */\n$includes{$hfile}!;
	    $c =~ s!$include!/* $nohash - no include guard */!g;
	}
	else {
	    $c =~ s!$include!/* $nohash */\n$includes{$hfile}!g;
	}
    }
    else {
	warn "$hfile not found";
    }
}

# Solaris doesn't like len_t:
# http://www.cpantesters.org/cpan/report/14fb7626-6e2f-11eb-84bc-edd243e66a77

$c =~ s!\blen_t\b!libdeflate_len_t!g;

# Restore #

$c =~ s!hashhashhash!#!g;

write_text ("$Bin/libdeflate-one.c", $c);
# Test compilation
system ("cc -c $Bin/libdeflate-one.c");
# Remove the o file, we are going to include the C file in our thing.
unlink "$Bin/libdeflate-one.o" or die $!;

if (! keys %version) {
    die "No version information was found";
}
write_json ("$Bin/version.json", \%version);

exit;
