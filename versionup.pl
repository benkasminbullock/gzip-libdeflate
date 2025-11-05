#!/home/ben/software/install/bin/perl

# The CPAN perl-reversion script seems to be making a muddle of things
# sometimes, and it doesn't edit Changes, so I've made my own script.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use File::Slurper qw!read_text write_text!;
use Deploy 'make_date';

my $version = '0.11_01';
my $newversion = '0.12';

my @pmfiles = qw!
    lib/Gzip/Libdeflate.pm
!;

for my $file (@pmfiles) {
    my $bfile = "$Bin/$file";
    my $text = read_text ($bfile);
    if ($text =~ s/\Q$version\E\b/$newversion/g) {
	print "$file OK\n";
	write_text ($bfile, $text);
    }
    elsif ($text =~ /'\Q$newversion\E'/) {
	warn "$file already at $newversion";
    }
    else {
	warn "$file failed";
    }
}


