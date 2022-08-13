addPrefixedFunction 'perl' 'init' 'Init'
perl_init() {
  <<EOF cat -
#!/usr/bin/perl

use v5.28;                     # in perluniintro, latest bug fix for unicode
use feature 'unicode_strings'; # enable perl functions to use Unicode
use Encode 'decode_ut8';       # so we do not need -CA flag in perl
use utf8;                      # source code in utf8
use strict 'subs';             # only allows declared functions
use warnings;

binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

#run: perl -T %
my %cmds = (
  "--local" => ["description", sub {
  }],

  "clean" => ["Remove the direcotry", sub {
    say STDERR "Removing public dir (WIP on cache too)...";
    `rm -r \\Qdirectory\\E`;
  }],

  "all" => ["Clean and build everything", sub {
    my_make("clean", "--local");
  }],
);

sub help {
  print(<<'EOF  ');
SYNOPSIS
  $0

DESCRIPTION
  Functions much like a Makefile

SUBCOMMANDS
  EOF

  my $len = max(map { length $_ } keys %cmds);
  for my $key (keys %cmds) {
    printf "  %-${len}s    %s\n", $key, $cmds{$key}[0];
  }
  exit 1;
}

sub main {
}


main
EOF
}

addPrefixedFunction 'perl' 'all_stdin' 'Read all of stdin as a str'
perl_all_stdin() { printf %s 'my $stdin = do { local $/ = ""; <STDIN> };'; }

addPrefixedFunction 'perl' 'regexp_parse' 'Parse via regex'
perl_regexp_parse() {
  <<EOF cat -
while (\$<> =~ /\G<>/gc) {
  <>
}
EOF
}




addPrefixedFunction 'perl' 'find' 'Recursively walk through each directory'
perl_find() {
<<EOF cat -
  my @files;
find({
  # After readdir() before wanted(), for editing which dirs to process
  #preprocess => sub {
  #  my @list = @_;
  #  return grep { $_ !~ /pattern/ } @_;
  #},
  wanted => sub {
    my $path = $File::Find::name;
    return if -d $path;
    say "blah: $path";
  },

  # Not sure exactly what this needs to be, but enables `perl -T %`
  untaint => sub {},
}, cwd() . "/published" );
EOF
}


