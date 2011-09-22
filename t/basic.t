#!/usr/bin/env perl
#
# Basic test
#

use strict;
use warnings;
use TicketServer;
use Test::More;

my $host     = 'localhost';
my $port     = 3306;
my $dbname   = 'tickets';
my $dsn      = "DBI:mysql:dbname=$dbname;host=$host;port=$port";
my $user     = 'root';
my $password = '';

#
# Change here if you have custom auto_increment settings
#
my $auto_incr_incr =   1;  # 10
my $auto_incr_offset = 0;  # 2

sub auto_incr_num {
    my $n = shift;
    $n *= $auto_incr_incr;
    $n += $auto_incr_offset;
    return $n;
}

my $tm = TicketServer->new({
    dsn => $dsn,
    user => $user,
    password => $password,
});

ok $tm, 'TicketServer object created';


my $seq = 'users_sequence';
ok $tm->reset_sequence($seq, 800_000_000_000),
    "reset_sequence() with value";

my $count = 10;
while ($count--) {
    my $next = $tm->next_val($seq);
    is $next => 800_000_000_000 + auto_incr_num(9 - $count),
        "reset_sequence() with a value works [$next]";
}

ok $tm->reset_sequence($seq), "reset_sequence() without value";

$count = 10;

while ($count--) {
    my $next = $tm->next_val($seq);
    is $next => 1 + auto_incr_num(9 - $count),
        "reset_sequence() without values + next_val() works [$next]";
    #diag $next;
}

ok $tm->reset_sequence($seq, 1000), "reset_sequence() with a lower value";

$count = 10;

while ($count--) {
    my $next = $tm->next_val($seq);
    is $next => 1000 + auto_incr_num(9 - $count),
        "reset_sequence() again with a value [$next]";
    #diag $next;
}

$seq = 'photos';

ok $tm->create_sequence($seq, 500_000_000_000_000),
    "create a new sequence with a starting value";

$count = 100;

while ($count--) {
    my $next = $tm->next_val($seq);
    is $next => 500_000_000_000_000 + auto_incr_num(99 - $count),
        "reset_sequence() again with a value [$next]";
    #diag $next;
}

ok $tm->drop_sequence($seq),
    "drop an existing sequence";

done_testing;

