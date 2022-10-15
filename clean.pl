#!/home/ben/software/install/bin/perl
use Z;
unlink "$Bin/version.json" or die $!;
unlink "$Bin/libdeflate-one.c" or die $!;
