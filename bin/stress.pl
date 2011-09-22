#!/usr/bin/env perl

=pod

=head1 NAME

stress.pl - Stress test ticket server db

=head1 SYNOPSIS

    # No option, defaults to:
    # "DBI:mysql:dbname=tickets; host=localhost; port=3306"
    ./stress.pl

    # Recognized options
    ./stress.pl
        --host <hostname>             # "localhost"
        --port <port>                 # 3306
        --driver <DBI-Driver-Name>    # "mysql"
        --dbname <db-name>            # "tickets"
        --username <db-user>          # "root"
        --password <db-pass>          # ""
        --mysql-engine <MySQL-Engine> # "MyISAM"

=head1 DESCRIPTION

Long-term stress-test for the ticket db.
Measures operations per second.

CTRL+C to interrupt.

=head1 SEE ALSO

L<https://github.com/cosimo/TicketServer>

=cut

use strict;
use warnings;

# Find our '../lib' from wherever we're invoked
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Getopt::Long ();
use Pod::Usage   ();
use Time::HiRes  ();

use TicketServer;

Getopt::Long::GetOptions(
    # ':' is optional, 's' is string, 'i' is int
    'host:s'     => \(my $host     = 'localhost'),
    'driver:s'   => \(my $driver   = 'mysql'),
    'port:i'     => \(my $port     = 3306),
    'dbname:s'   => \(my $dbname   = 'tickets'),
    'username:s' => \(my $username = 'root'),
    'password:s' => \(my $password = ''),
    'mysql-engine:s' => \(my $engine = 'MyISAM'),
) or Pod::Usage::pod2usage(-verbose => 2);

my $dsn = "DBI:$driver:dbname=$dbname;host=$host;port=$port";

my $tm = TicketServer->new({
    dsn      => $dsn,
    driver   => $driver,
    user     => $username,
    password => $password,
    engine   => $engine,
});

my @seq = ('s1' .. 's6');

for (@seq) {
    $tm->drop_sequence($_);
    $tm->create_sequence($_);
}

my $gets  =
my $done  =
my $total = 0;

# CTRL + C sends us a SIGINT
$SIG{INT} = sub { $done = 1 };

# We need to unbuffer STDOUT to show progress status
$| = 1;

my $start_time = [ Time::HiRes::gettimeofday() ];
my %values;

while (not $done) {

    # Increment a random sequence of the <n> we have
    my $random_seq = $seq[int rand(@seq)];
    my $val = $tm->next_val($random_seq);

    $gets++;
    $total++;

    $values{$random_seq} = $val;

    # Show some progress every now and then
    if ($total % 5000 == 0) {

        my $elapsed = Time::HiRes::tv_interval($start_time);
        my $per_sec = int ($gets / $elapsed);
        $start_time = [ Time::HiRes::gettimeofday() ];
        $gets = 0;

        my $out = "ops:$total ($per_sec/s)   [";
        my $sp = "";
        for (@seq) {
            $out .= $sp . $_ . ':' . $values{$_};
            $sp = " ";
        }

        $out .= "] \r";

        print $out;
    }

}

