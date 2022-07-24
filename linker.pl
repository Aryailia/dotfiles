#!/usr/bin/perl
# This is a rewrite of a POSIX sh script that you can find in './share/linker'
#
# This setup is intended to be:
# - portable across *nix systems (redox, debian, and void)
# - portable across Android with Termux
# - portable across Windows with MYSGIT
# - portable across MacOS (currenttly without a test Mac, but it is unix-based)
# - easily deployable in a virtual machine environment
# - target bash, but sourceable with feature-parity to other shells (eg. ion)

# TODO: backup bookmarks?
# TODO: if folder is a symlink, it will delete the config file in dotfiles
# TODO: Check if foward-slash is reserved character on MSYGIT (windows)

use v5.28;                     # in perluniintro, latest bug fix for unicode
use feature 'unicode_strings'; # enable perl functions to use Unicode
use Encode 'decode_utf8';      # so we do not need -CA flag in perl
use utf8;                      # source code in utf8
use strict;
use warnings;

use File::Find 'find';
use Cwd 'realpath';
use File::Basename 'dirname';

my $LINKER_CONFIG = '.linkerconfig';
my $DESCRIPTION = <<EOF;
  This deploys this \$dotfiles directory (the directory that this file resides
  in) and the \$DOTENVIRONMENT directory, with the same file structure,
  by symlinks those into '--output DIR' (which defaults to \$HOME).

  Most of the relevant constants, excluding \$HOME, including \$DOTENVIRONMENT,
  \$SCRIPTS, etc. are defined in '\$dotfiles/.profile' or in this file under
  the 'main' subroutine.

  By default, this recurses through the \$dotfiles directory and symlinks the
  child files. This means empty directories are ignored. But you can customise
  it through '\$dotfiles/$LINKER_CONFIG' in '\$DOTENVIRONMENT/$LINKER_CONFIG',
  choosing what files to ignore and directories to recurse no further and only
  symlink by directory.

  You can choose how to handle replacing files that already exist with the flags

  Named directories in bash are handled by \$CDPATH. I do not make use of this
  for reasons I have forgotten, something to do with the ergonomics. Instead
  I make use of an alias `c` + `namedpath.sh` in the \$SCRIPTS directory. This
  is useable across shells with some adaptation.
EOF


binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $FLAG = 0; # Does not take an arg, e.g. --verbose
my $ARG = 1;  # Takes an argument,    e.g. --target hello

# short (optional), long, aliases (with ignore), bool, short desc, long desc
my $SHORT = 0;
my $LONG = 1;
my $ALIASES = 2;
my $TAKE_ARG = 3;
my $SHORT_DESCRIPTION = 4;
my $LONG_DESCRIPTION = 5;
my @OPTIONS = sort { $a->[$LONG] cmp $b->[$LONG] } (
  ["f", "force", [], $FLAG, "Rewrite all", "
    Deletes the destination forcefully and symlinks. In particular, this is
    Useful if programs are run and the config files are already created in
    order to replace them with the dotfiles"
  ],

  ["c", "cautious", [], $FLAG, "Only rewrite symlinks", "
    Only replaces symlinks if the destination files are they themselves
    symlinks. Useful if directory changes occured and don't want to destroy
    existing customisations."
  ],

  ["i", "ignore", [], $FLAG, "Skip if file exists", "
    Does not replace with the symlink if the destination file already exists.
    The default behaviour and useful if you want to keep your current config"
  ],

  ["h", "help", [], $FLAG, "Display long help", "
    Display this help menu"
  ],

  ["o", "output", [], $ARG, "Set destination directory to ARG", "
    Changes the destination to which all the config files are symlinked
    Default is '\${HOME}'"
  ],

  ["v", "verbose", [], $FLAG, "Verbose output", "
    Mutes any warnings (ie. when symlinks are left alone because they already
    exist)"
  ],
);

#TODO: test on termux

$ENV{'PATH'} = '/bin';  # For -T taint
my $HOME = $ENV{'HOME'};
-d $HOME or die "\$HOME does not exist. \$HOME provided: '$HOME'";

my $STANDARD = 0;
my $CAUTIOUS = 1;
my $FORCE = 2;
my %CONFIG = (
  verbose => 0,
  level => $STANDARD,
);



#run: perl -T % -o $HOME
sub main {
  my %valid_opt = parse_valid_options(@OPTIONS);
  my ($opts, $args) = parse_args(\%valid_opt, \@OPTIONS, @ARGV);
  my $i = 0;

  while ($i < $#$opts) {
    if    ($opts->[$i] eq $valid_opt{'h'}) { show_help("long"); exit 1; }
    elsif ($opts->[$i] eq $valid_opt{'v'}) { $CONFIG{'verbose'} = 1; }
    elsif ($opts->[$i] eq $valid_opt{'o'}) { $CONFIG{'output'} = $opts->[$i+1]; }
    elsif ($opts->[$i] eq $valid_opt{'c'}) { $CONFIG{'level'} = $CAUTIOUS; }
    elsif ($opts->[$i] eq $valid_opt{'f'}) { $CONFIG{'level'} = $FORCE; }
    else { die "DEV: Did not handle --$OPTIONS[$opts->[$i+1]][$LONG]"; }

    $i += 2;
  }
  if (scalar(@$args) > 0) {
    say STDERR "No arguments expected";
    show_help("short");
    exit 1;
  }

  ######
  # Args
  my $dotfiles = dirname(realpath(__FILE__));
  $dotfiles = $dotfiles =~ /([\s\S]+)/ ? $1 : die '$dotfiles empty?'; # detaint
  #my $dotfiles = "/home/rai/dotfiles";
  my $target = defined $CONFIG{'output'} ? $CONFIG{'output'} : $HOME;

  ############################
  # Constants (customise here)
  my $profile = "$dotfiles/.profile";
  my %my_env = source("$profile");

  my $rel_linker_config = "./$LINKER_CONFIG"; # Edit this at $LINKER_CONFIG
  my $dotenv = $my_env{'DOTENVIRONMENT'};
  my $rel_scripts = ".config/scripts";
  my $make_shortcuts = "$dotfiles/$rel_scripts/named-dirs.sh";
  my $vim_plugin_manager_saveto="$my_env{'XDG_CONFIG_HOME'}/nvim/autoload/plug.vim";
  my $vim_plugin_manager_dllink="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim";

  my $source_scripts = "$dotfiles/$rel_scripts";
  my $target_scripts = "$target/$rel_scripts";
  $my_env{'SCRIPTS'} eq "$target_scripts" or die
    "Update \$rel_scripts in '$0' to match \$SCRIPTS defined in '$profile'. \
    '$target_scripts' != '$my_env{'SCRIPTS'}'";



  ###################
  # Start doing stuff
  -d $target or die "Output directory '$target' does not exist.";
  mkdir_p($my_env{'XDG_CONFIG_HOME'});
  mkdir_p($my_env{'XDG_CACHE_HOME'});

  say STDERR "======== Special case ========";
  say STDERR "Set execute flag \$SCRIPTS in dotfiles directory... ";
  system("/usr/bin/find", $source_scripts, "-exec", "/bin/chmod", "755", "{}", "+");

  # Named directories
  say STDERR "Making named directories...";
  if (-x "${make_shortcuts}") {
    `/usr/bin/env PATH="$my_env{'PATH'}" /bin/sh "$make_shortcuts"`;
  } else {
    say STDERR "! Shortcuts script '$make_shortcuts' not found/executable"
  }

  if (-f $vim_plugin_manager_saveto) {
    $CONFIG{'verbose'} and say STDERR "✓ Already downloaded vim plugin manager";
  } else {
    system("/usr/bin/curl", "--create-dirs", "-fLo",
      $vim_plugin_manager_saveto, $vim_plugin_manager_dllink);
    say STDERR "✓ Downloaded vim plugin manager";
  }

  say STDERR '';
  say STDERR "======== $dotfiles ========";
  link_fromto_according_to_config($dotfiles, $target, "$dotfiles/$rel_linker_config");

  say STDERR '';
  say STDERR "======== $dotenv ========";
  link_fromto_according_to_config($dotenv, $target, "$dotenv/$rel_linker_config");
  #link_fromto_according_to_config("/home/rai/dotfiles", "./a", "./config");
}

################################################################################
# The primary worker of this script
sub link_fromto_according_to_config {
  my ($source, $output, $config) = @_;
  $output = realpath($output);

  ###
  # Read and parse the config file, a series of directives + m/$pattern/x
  my $document = do {
    local $/ = undef;
    open(my $CFG, "<:encoding(utf-8)", $config)
      or die "Cannot open file '$config'";
    <$CFG>;
  };

  my @ignore;
  my @directory;
  my $row = 0;
  pos($document) = 0;
  while ($document =~ m{
      \G\s*\n
      | \G \# .* \n
      | \G (ignore|directory):(.*)\n
      | (.*)\n
    }xcg
  ) {
    $row += 1;
    if (defined $3) {
      die "Bad syntax at:\n    $row | $3\n",
        "Must start with 'ignore:' or 'directory:'.\n";
    } elsif (defined $1) {
      if ($1 eq 'ignore') {
        push @ignore, $2;
      } elsif ($1 eq 'directory') {
        my $path = "$source/$2";
        die "Config error\n     $row | directory:$2\n'$path' does not exist"
          if not -e $path;
        die "Config error\n     $row | directory:$2\n'$path' is a file"
          if not -d $path;

        push @directory, $2;
      } else {
        die 'DEV: invalid case';
      }
    }
  }

  ###
  # Apply rules and create the symlinks
  my $count = 0;
  find({
    preprocess => sub {
      my $dir = $File::Find::name;
      if ($dir ne $source) {
        my $reldir = substr($dir, length($source) + 1);

        # Skip considering the children in $dir if our config file specifies
        # symlinking the entire directory
        for my $literal (@directory) {
          if ($reldir eq $literal) {
            # Directories skipped here are still added to @list though when
            # expanding its parent. Unless one of the parents are ignored.
            return ();
          }
        }
        mkdir_or_die("$output/$reldir");
      }

      my @list;
      outer: for my $name (@_) {
        next if $name eq '.' || $name eq '..';

        my $relpath =  substr("$dir/$name", length($source) + 1);
        for my $pattern (@ignore) {
          if ($relpath =~ m/$pattern/x) {
            say STDERR "Ignoring: '$relpath'" if $CONFIG{'verbose'};
            next outer;
          }
        }

        # Normally it would be fine to not skip the directories in @directory,
        # but there is one special case:
        #
        # e.g. ignore:\A .git \z
        #      directory:.git/hooks
        #
        # i.e. ignore child node of '.git' and only include '.git/hook'

        # Actually we skip directories in \&wanted, so we do not need this
        #for my $tolink_dir (@directory) {
        #  next outer if ($relpath eq $tolink_dir);
        #}

        push @list, $name;
      }
      return @list;

    },
    wanted => sub {
      my $source_path = $File::Find::name;
      return if -d $source_path;

      $count += 1;
      my $relpath = substr($source_path, length($source) + 1);
      custom_symlink($source_path, "$output/$relpath", $relpath);
    },

    # Not sure exactly what this needs to be, but enables `perl -T %`
    untaint => sub {},
  }, $source);

  ###
  # Link directories
  say STDERR '';
  say STDERR 'Processing directories...';
  for my $tolink_dir (@directory) {
    custom_symlink("$source/$tolink_dir", "$output/$tolink_dir", $tolink_dir);
    $count += 1;
  }
  say STDERR "$count nodes processed";
}

################################################################################
# Wrappers for Shellscript

# Does the shellscript '.' or the bash script 'source' command
#
# An alternative to our own implementation is wrapping this perl script in
#     <<'__END__' cat - | perl "$@"
# Quotes on the delimiter disable variable expansions
# See: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_02
sub source {
  #`/usr/bin/env -i HOME="$HOME" /bin/sh -c '. $_[0];/bin/env'`;
  my $exports = `/usr/bin/env -i HOME="$ENV{'HOME'}" /bin/sh -c '. $_[0]; /usr/bin/env'`
    or die "Failed to source '$_[0]'";

  my $row = 0;
  my %my_env;
  for my $line (split /\n/, $exports) {
    if ($line =~ /^([A-Za-z_][0-9A-Za-z_]*)=(.*)$/) {
      $my_env{$1} = $2;
    } else {
      die "This script does not support\n    $row |$line\nin '$_[0]'";
    }
    $row += 1;
  }
  return %my_env;
}

sub mkdir_or_die {
  $_[0] =~ /([\s\S]+)/ or die "Cannot mkdir an empty string";
  if (! -d $1 ) {
    die "'$1' exists as a file" if -e $1;
    mkdir($1) or die "Cannot make directory '$1'. Permissions error?";
  }
}


sub mkdir_p {
  my $path = "";
  for my $part (split m!/!, $_[0]) {
    $path .= "$part/";
    mkdir_or_die($path);
  }
}

sub custom_symlink {
  #$_[0] =~ /([\s\S]+)/;
  my $from = $_[0] =~ /([\s\S]+)/ ? $1 : die 'Empty arg: 0';
  my $into = $_[1] =~ /([\s\S]+)/ ? $1 : die 'Empty arg: 1';
  my $rel_part = defined $_[2] ? $_[2] : die 'Empty arg: 2';

  my $act = $CONFIG{'level'};
  if (($act == $FORCE) or ($act == $CAUTIOUS && -l $into)) {
    system("/bin/rm", "-f", $into) and die "Could not remove '$into'";
  }

  if (-e $into) {
    say STDERR "! WARN: Skipping '$rel_part' since --force not specified"
      if $CONFIG{'verbose'};
  } else {
    if (-l $from) {
      system("/bin/cp", "-P", $from, $into)
        and die "Could not copy '$from'->'$into'";
      say STDERR "✓ SUCCESS: Copied '$rel_part'";
    } else {
      system("/bin/ln", "-s", $from, $into)
        and die "Could not symlink '$from'->'$into'";
      say STDERR "✓ SUCCESS: Linked '$rel_part'";
    }
  }
}


################################################################################
# Argument and Option parsing
sub parse_valid_options {
  my %valid_options;
  my @options_spec = @_;
  my $index = 0;
  for my $option_def (@options_spec) {
    length($option_def->[$SHORT]) <= 1 or die
        "DEV: Short options are the empty string or one character";

    if (length($option_def->[$SHORT]) == 1) {
      $valid_options{$option_def->[$SHORT]} = $index;
    }

    $valid_options{$option_def->[$LONG]} = $index;
    for my $alias (@{$option_def->[$ALIASES]}) {
      $valid_options{$alias} = $index;
    }
    ++$index;
  }
  return %valid_options;
}

sub parse_args {
  my %valid_options = %{shift()};
  my @options_spec = @{shift()};

  my $stdin = 0;
  my $literal = 0;
  my @opts;
  my @args;
  while (scalar(@_) > 0) {
    my $arg = shift();
    if (!utf8::is_utf8($arg)) {
      $arg = Encode::decode_utf8($arg);
    }

    my @to_check;
    if ($literal) {
      push @args, $arg;
    } elsif ($arg eq "-") {
      $stdin = 1;
    } elsif ($arg eq "--") {
      $literal = 1;
    } elsif (substr($arg, 0, 2) eq "--") {
      push @to_check, substr($arg, 2);
    } elsif (substr($arg, 0, 1) eq "-") {
      @to_check = split //, substr($arg, 1);
    } else {
      push @args, $arg;
    }

# run: perl -T % -o a h --help yo
# run: perl -CA -T % -o a -你 --help yo
    for my $i (0..$#to_check) {
      my $o = $to_check[$i];
      my $index = $valid_options{$o};

      if (not exists $valid_options{$o} or not defined $valid_options{$o}) {
        say STDERR "FATAL: Invalid option '" . (length($o) <= 1 ? "-$o" : "--$o") . "'";
        show_help("short");
        exit 1;
      } elsif ($OPTIONS[$index][$TAKE_ARG]) {
        if ($i != $#to_check) {
          say STDERR "FATAL: Option '$o' takes an argument";
          show_help("short");
          exit 1;
        } else {
          push @opts, $index;
          push @opts, decode_utf8(shift(@_));
        }
      } else {
        push @opts, $index;
        push @opts, 1;
      }
    }
  }

  return \@opts, \@args;
}

sub show_help() {
  my $NAME = $0;
  my $synopsis = "$NAME [OPTION]";
  my $long_help = <<EOF;
SYNOPSIS
  $synopsis;

DESCRIPTION
$DESCRIPTION

ARGUMENTS
  -
    Using '-' for an argument means pipe it

OPTIONS

EOF
  # Adds --
  my $literal = ["", "", [], $FLAG, "Stop parsing subsequent args as options", "
    Makes all subsequent arguments not be interpretted at options. Good for
    passing files names that begin with a hyphen/dash."
  ];
  my @options_spec = ($literal, @OPTIONS);
  # Short
  if ($_[0] eq "short") {
    say $synopsis;

    # Calculate the padding
    my $padding = 0;
    for my $def (@options_spec) {
      for ($def->[$LONG], @{$def->[$ALIASES]}) {
        my $len = length($_);
        $padding = $padding > $len ? $padding : $len;
      }
    }

    for my $def (@options_spec) {
      print "  ";
      print($def->[$SHORT] ne "" ? "-$def->[$SHORT], " : "    ");
      printf("--%-${padding}s  ", $def->[$LONG]);
      print($def->[$TAKE_ARG] ? "ARG": "   ");
      print "  ";
      say $def->[$SHORT_DESCRIPTION];
      for (@{$def->[$ALIASES]}) {
        printf("      %-${padding}s  ", $_);
        say '';
      }
    }

  # Long
  } elsif ($_[0] eq "long") {
    print $long_help;

    # Assume @options is sorted already
    for my $def (@options_spec) {
      # print options
      print "  ";
      my $i = 0;
      my @opts;
      $def->[$SHORT] ne "" and push(@opts, "-$def->[$SHORT]");
      $def->[$LONG]  ne "" and push(@opts, " --$def->[$LONG]");
      print join(", ", (@opts, @{$def->[$ALIASES]}));
       #print join(", ", ("-$entry[1]", "--$long", @{$entry[2]}));
        #}

      print "$def->[$LONG_DESCRIPTION]\n\n";
    }
  } else {
    die "DEV: pass `show_help()` the 'short' or 'long' argument"
  }
}

main();
