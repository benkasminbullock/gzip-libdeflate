#!/home/ben/software/install/bin/perl
use Z;
my @files = qw!
    version.json
    libdeflate-one.c
    libd-copyr
!;
for my $file (@files) {
    if (-f $file) {
	unlink "$Bin/$file" or die $!;
    }
}
