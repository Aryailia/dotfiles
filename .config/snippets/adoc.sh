#addPrefixedFunction 'init' 'Init'
#perl_init() {
#  <<EOF cat -
##!/usr/bin/perl
#
#use v5.28;                     # in perluniintro, latest bug fix for unicode
#use feature 'unicode_strings'; # enable perl functions to use Unicode
#use Encode 'decode_ut8';       # so we do not need -CA flag in perl
#use utf8;                      # source code in utf8
#use strict 'subs';             # only allows declared functions
#use warnings;
#
#binmode STDIN, ':encoding(utf8)';
#binmode STDOUT, ':encoding(utf8)';
#binmode STDERR, ':encoding(utf8)';
#
##run: perl -T %
#
#EOF
#}

addPrefixedFunction 'adoc' 'fn' 'Footnote'
adoc_fn() { printf %s '{wj}footnote:[<>]'; }
