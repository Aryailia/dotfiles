#!/usr/bin/env perl

use strict;
use warnings;
# use unicode_strings;


my $pattern = $ARGV[0];
my $to_prefix = $ARGV[1];  # Everything but the first
if ($#ARGV <= 1) {
  print "\n";
  exit 1;
}

sub generator {
  my $buffer = "";
  return sub {
    my $self = $_;
    #$buffer !~ /^$pattern/ && print "yes\n";
    while ($buffer !~ /^$pattern/s && defined($_ = <STDIN>)) {
      $buffer .= $_;
    }
    if ($buffer =~ /^(.*?)$pattern(.*)/s) {
      $buffer = $2;
      return $1;
    } else {
      my $temp = $buffer;
      $buffer = "";
      return $temp;
    }
  };
}
my $fetch_token = generator();
my $first = 1;
#while (($_ = $fetch_token->()) ne "") {
#  system($ARGV[2], @ARGV[3 .. $#ARGV], ($first ? "" : $to_prefix) . $_);
#  $first = 0;
#}


# Dump it all
my @args;
while (($_ = $fetch_token->()) ne "") {
  push @args, ($first ? "" : $to_prefix) . $_;
  $first = 0;
}
#print @args;
system($ARGV[2], @ARGV[3 .. $#ARGV], @args);


exit;

#use GetOpt::Long;
#print 'yo';
#my $delimiter = $ARGV[0];
#my @a = (@ARGV, 2);
#print "yo @a";


#system("echo", "b");


#sub { print $_[0] } -> (sub { $_[0] * 2 } -> (3))
#my @a = (1, 2, 3, 4, 5);
#my @b = map { $_ + 3 } 
#        map { $_ * 2 }
#        @a;
#print "@b";
