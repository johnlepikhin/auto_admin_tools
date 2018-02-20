#!/usr/bin/perl

use warnings FATAL => 'all';
use strict;
use Getopt::Long;
use Carp qw(cluck croak confess);

my $opt_sleep      = 1;
my $opt_iterations = 2**62;
my $opt_indent     = 0;
my $opt_command;
my $opt_color    = 0;
my $opt_no_clear = 0;
my $opt_ignore;

GetOptions(
    's=f'      => \$opt_sleep,
    'n=i'      => \$opt_iterations,
    'c=s'      => \$opt_command,
    'i'        => \$opt_indent,
    'no-clear' => \$opt_no_clear,
    'color'    => \$opt_color,
    'ignore=s' => \$opt_ignore,
) || croak "Cannot parse command line arguments";

if ( !defined $opt_command ) {
    croak "-c 'command' is expected";
}

if ( !defined $opt_ignore ) {
    $opt_ignore = "(?!)";
}

my @prev;
for ( 1 .. $opt_iterations ) {
    open( my $fh, '-|', $opt_command ) || croak "Cannot execute command: $!";
    my $output;
    { local $/ = q{}; $output = <$fh>; }
    close $fh;

    if ( defined $output ) {
        my @new = split m{($opt_ignore|[+-]?\d*[.]?\d+)}, $output;
        if ( scalar @prev == scalar @new ) {
            if ( !$opt_no_clear ) {
                print "\x1b[3J\x1b[H\x1b[2J";
            }
            for my $pos ( 0 .. $#new ) {
                if ( $new[$pos] =~ m{^$opt_ignore$} ) {
                    print $new[$pos];
                } elsif ( $new[$pos] =~ m{[+-]?\d*[.]?\d+} ) {
                    my $v = $new[$pos] - $prev[$pos];
                    if ( $v > 0 ) {
                        $v = "+$v";
                    }
                    if ($opt_color) {
                        if ( $v > 0 ) {
                            print "\x1b[0;32m";
                        } elsif ( $v < 0 ) {
                            print "\x1b[0;31m";
                        }
                    }
                    if ($opt_indent) {
                        my $len = length $new[$pos];
                        printf "% ${len}s", $v;
                    } else {
                        print $v;
                    }
                    if ( $opt_color && $v ) {
                        print "\x1b[0m";
                    }
                } else {
                    print $new[$pos];
                }
            }
        }
        @prev = @new;
    }

    select undef, undef, undef, $opt_sleep;
}
