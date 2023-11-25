#!/usr/bin/env perl

# This is mostly for use with ${fs} and ${fx} of `lf`
# and for use by my own ./batch-rename.sh

# run: printf 'echo\necho\necho\nb' | % '\n' '/'
# run: printf '你 a\n好\n嗎\nb' | % '\n' '/' sh -c 'for a in "$@"; do echo $a; done' _
#run: printf '你 a好嗎b' | % '\n' '/' sh -c 'for a in "$@"; do echo $a; done' _

use v5.14;
use strict;
use feature 'unicode_strings'; # enable perl functions to use Unicode
use warnings;
use utf8;

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

# https://perldoc.perl.org/perlretut#Using-regular-expressions-in-Perl
my $pattern = $ARGV[0];
my $to_prefix = $ARGV[1];
$#ARGV >= 1 or die "Not enough arguments:
  Usage: $0 <regex> <replacement> [cmd/args...]
";

# Do not split on newlines
my $buffer = do { local $/ = ""; <STDIN> };

# s: single line ('.' matches newlines)
# g: multiple matches (allows \G, for where match left off)
# c: do not reset position on fail match (for `pos $buffer`)
my $x = 0;
my @args = $buffer =~ /\G(.+?)$pattern/scg;
push(@args, substr($buffer, (pos($buffer) or 0)));
@args = map { $to_prefix . $_ } @args;
exit(system(@ARGV[2 .. $#ARGV], @args));
