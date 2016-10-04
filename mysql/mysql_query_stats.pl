#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use DBI;
use Time::HiRes qw(sleep);
use Data::Dumper;

my $opt_host = 'localhost';
my $opt_port = 3306;
my $opt_user = 'root';
my $opt_password = undef;
my $opt_help = 0;
my $opt_man = 0;
my $opt_interval = 100;

GetOptions('h=s' => \$opt_host
           , 'host|h=s' => \$opt_host
           , 'password|p=s' => \$opt_password
           , 'user|u=s' => \$opt_user
           , 'port=i' => \$opt_port
           , 'interval|i=i' => \$opt_interval
           , 'help|?' => \$opt_help
           , 'man|?' => \$opt_man
    );

pod2usage(-exitval => 0, -verbose => 2) if $opt_man;
pod2usage(1) if $opt_help;

if (!defined ($opt_password)) {
    printf STDERR "\nOption --password is required!\n\n";
    pod2usage(1);
}

printf "host = $opt_host, user = $opt_user\n";

# Connect to the database.
my $dbh = DBI->connect("DBI:mysql:host=$opt_host;port=$opt_port",
                       $opt_user, $opt_password,
                       {'RaiseError' => 1});

my %stat;

my $query = 'show full processlist';

while (1) {
    foreach my $row (@{$dbh->selectall_arrayref($query)}) {
        my $info = $row->[7];

        if (defined $info && $info ne $query) {
            $info =~ s/[\n\t ]+/ /g;
            $info =~ s/"(?:[^\\"]|\\.)*"/"..."/g;
            $info =~ s/'(?:[^\\']|\\.)*'/'...'/g;
            $info =~ s/([^a-zA-Z\d_]?)\d+/${1}00/g;
            $info =~ s/\(((00|'\.\.\.'|"\.\.\.")(, *)?)*\)/(...)/g;
            # TODO: lowercase
            $stat{$info}++;
        }
    }
    sleep($opt_interval/1000);

    if ((keys %stat) > 0) {
        print "-------------------------------------------------\n";
        foreach (sort { $stat{$b} <=> $stat{$a} } keys %stat) {
            print "$stat{$_}   $_\n\n";
        }
    }
}

__END__

=head1 NAME

mysql_query_stats - Statistical profiler for MySQL

=head1 SYNOPSIS

mysql_query_stats --password <password> [options]

=head1 OPTIONS

=over 8

=item B<--host> or B<-h>

MySQL host name. Default value B<localhost>.

=item B<--port>

MySQL port. Default value B<3306>.

=item B<--user> or B<-u>

MySQL user name. Default value B<root>.

=item B<--password> or B<-p>

MySQL password. This option is required.

=item B<--interval> or B<-i>

Interval in milliseconds between two queries of processlist. Default value is 100ms.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

This program tries to gather queires statistics in the same way as OProfile does for Linux kernel.

It periodically sends C<show full processlist> parse response and collects queries of the same type. For example,
C<select * from tbl where id=1> and C<select * from tbl where id=999> are counted with the same type.


=cut

