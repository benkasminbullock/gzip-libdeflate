# This is a test for module Gzip::Libdeflate.

use warnings;
use strict;
use utf8;
use Test::More;
use_ok ('Gzip::Libdeflate');
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use FindBin '$Bin';

use Gzip::Libdeflate;
my $c = Gzip::Libdeflate->compressor ();
my $in = "monkey business! " x 100;
my $out = $c->gzip_compress ($in);
cmp_ok (length ($out), '<', length ($in), "Compressed");
my $d = Gzip::Libdeflate->decompressor ();
my $rt = $d->gzip_decompress ($out);
is ($rt, $in, "Round trip");

open my $gzin, "<:raw", "$Bin/index.html.gz" or die $!;
my $guff = '';
while (<$gzin>) {
    $guff .= $_;
}
print $d->gzip_decompress ($guff);

done_testing ();
# Local variables:
# mode: perl
# End:
