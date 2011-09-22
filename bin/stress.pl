#!/usr/bin/env perl
#
# Long-term stress-test for the ticket db
#

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$FindBin::Bin/../lib";

use Time::HiRes;
use TicketServer;

my $host     = 'localhost';
my $port     = 3306;
my $dbname   = 'tickets';
my $user     = 'root';
my $password = '';

my $dsn = "DBI:mysql:dbname=$dbname;host=$host;port=$port";

my $tm = TicketServer->new({
    dsn => $dsn,
    user => $user,
    password => $password,
});

my @seq = qw(s1 s2 s3 s4 s5 s6);

for (@seq) {
    $tm->drop_sequence($_);
    $tm->create_sequence($_);
}

my $ticks =
my $gets =
my $done =
my $total = 0;

$SIG{INT} = sub { $done = 1 };
$| = 1;

my $start_time = [Time::HiRes::gettimeofday()];
my %values;

while (not $done) {
    $ticks++;

    my $random_seq = $seq[int rand(@seq)];
    my $val = $tm->next_val($random_seq);
    $gets++;
    $total++;

    $values{$random_seq} = $val;

    if ($ticks % 5000 == 0) {
        my $elapsed = Time::HiRes::tv_interval($start_time);
        my $persec = int ($gets / $elapsed);
        $start_time = [Time::HiRes::gettimeofday()];
        $gets = 0;
        print "ops:$total ($persec/s)   [";

        for (sort keys %values) {
            print "$_:$values{$_} ";
        }

        print "]  \r";
    }

}

