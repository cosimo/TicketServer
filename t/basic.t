#!/usr/bin/env perl

=pod

=head1 NAME

t/mysql-sanity.t - Test suite for TicketServer

=head1 DESCRIPTION

Runs basic sanity checks on different MySQL engines.

=cut

use strict;
use warnings;
use Test::More;

use TicketServer;

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

my @test_engines = ('MyISAM', 'InnoDB');

for my $engine (@test_engines) {

    run_sanity_tests(
        dsn => $dsn,
        user => $user,
        engine => $engine
    );

}

done_testing;

#
# End of test


sub auto_incr_num ($) {
    my $n = shift;
    $n *= $auto_incr_incr;
    $n += $auto_incr_offset;
    return $n;
}

sub run_sanity_tests (@) {

    my %args = @_;

    my $engine = $args{engine} or die "No engine?";

    my $tm = TicketServer->new(\%args);
    ok $tm, 'TicketServer object created';

    my $seq = 'users_sequence';
    ok $tm->reset_sequence($seq, 800_000_000_000),
        "reset_sequence() with value [$engine]";

    my $count = 10;
    while ($count--) {
        my $next = $tm->next_val($seq);
        is $next => 800_000_000_000 + auto_incr_num(9 - $count),
            "reset_sequence() with a value works [$next]";
    }

    ok $tm->reset_sequence($seq),
        "reset_sequence() without value [$engine]";

    $count = 10;

    while ($count--) {
        my $next = $tm->next_val($seq);
        is $next => 1 + auto_incr_num(9 - $count),
            "reset_sequence() without values + next_val() works [$next] [$engine]";
        #diag $next;
    }

    ok $tm->reset_sequence($seq, 1000),
        "reset_sequence() with a lower value [$engine]";

    $count = 10;

    while ($count--) {
        my $next = $tm->next_val($seq);
        is $next => 1000 + auto_incr_num(9 - $count),
            "reset_sequence() again with a value [$next] [$engine]";
        #diag $next;
    }

    $seq = 'photos';

    ok $tm->create_sequence($seq, 500_000_000_000_000),
        "create a new sequence with a starting value [$engine]";

    $count = 100;

    while ($count--) {
        my $next = $tm->next_val($seq);
        is $next => 500_000_000_000_000 + auto_incr_num(99 - $count),
            "reset_sequence() again with a value [$next] [$engine]";
        #diag $next;
    }

    ok $tm->drop_sequence($seq),
        "drop an existing sequence [$engine]";

}

