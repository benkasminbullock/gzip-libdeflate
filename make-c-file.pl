#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use File::Slurper qw!read_text write_text!;
use C::Tokenize ':all';

my $verbose = 1;

my $dir = "$Bin/../../software/libdeflate-1.7";
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
    my $bfile = $file;
    my $hfile = $file;
    $bfile =~ s!.*/!!;
    $hfile =~ s!(x86|arm)-!$1/!g;
    my $text = read_text ($hfile);
    if ($hfile =~ m!(arm|x86)!) {
	my $type = $1;
     	$text =~ s!#\s*include\s*"(.*?)"!#include "$type-$1"!g;
	$text =~ s!$type-\.\./!!;
    }
    $text =~ s!$comment_re!!g;
    $includes{$bfile} = $text;
}

my $c = '';
for my $cfile (@cfiles) {
    if (-d $cfile) {
	next;
    }
    my $text = read_text ($cfile);
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
    $text =~ s!$comment_re!!g;
    $c .= "/* $cfile */\n";
    $c .= $text;
}

while ($c =~ m!
    (
	\#
	\s*
	include
	\s*
	[<"]
	.*?
	(
	    (?:common_defs
	    |compiler_(?:gcc|msc)
	    |lib_common
	    |libdeflate
	    |(?:arm|x86)-(cpu_features
		|crc32_pclmul_template)
	    |(?:x86|arm)/.*?
	    |adler32_vec_template
	    |crc32_vec_template
	    |crc32_table
	    |deflate_compress
	    |deflate_constants
	    |unaligned
	    |hc_matchfinder
	    |bt_matchfinder
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
	print "$hfile not found.\n";
    }
}

$c =~ s!hashhashhash!#!g;

write_text ("$Bin/libdeflate.c", $c);
# Test compilation
system ("cc -c $Bin/libdeflate.c");
# Remove the o file, we are going to include the C file in our thing.
unlink "$Bin/libdeflate.o" or die $!;
exit;

