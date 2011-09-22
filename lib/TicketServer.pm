package TicketServer;

use strict;
use warnings;

use Carp ();
use DBI;

sub new {
    my ($class, $args) = @_;

    $class = ref $class || $class;
    $args ||= {};

    my $self = {
        _dbh => undef,
        _dbname => undef,
        _dsn => $args->{dsn},
        _user => $args->{user},
        _password => $args->{password},
    };

    bless $self, $class;
}

sub connect {
    my ($self, $dsn, $user, $pass) = @_;

    $dsn  ||= $self->{_dsn};
    $user ||= $self->{_user};
    $pass ||= $self->{_password};

    if (! $dsn or ! $user) {
        Carp::croak("No DSN or user. Can't connect to tickets database!");
    }

    my $dbh = DBI->connect($dsn, $user, $pass, {
            RaiseError => 1,
            PrintError => 1
    })
        or return;

    if (! $dbh->ping()) {
        return;
    }

    my $dbname;
    if ($dsn =~ m{DBI : [^:]+ : (?:dbname=) (\w+)}ix) {
        $dbname = $1;
    }
    else {
        Carp::croak("Couldn't get database name from DSN $dsn");
    }

    $self->{_dbname} = $dbname;

    return $self->{_dbh} = $dbh;
}

sub drop_sequence {
    my ($self, $name) = @_;
    return unless defined $name && $name ne '';

    $name =~ s{\W}{}g ;

    my $sql = "DROP TABLE $name";
    my $dropped = 0;

    $dropped = eval {
        my $dbh = $self->get_dbh();
        my $sth = $dbh->prepare($sql);
        $dropped = $sth->execute();
        $sth->finish();
        return $dropped;
    };

    return $dropped;
}

sub reset_sequence {
    my ($self, $name, $start_value) = @_;

    $self->drop_sequence($name);
    $self->create_sequence($name, $start_value);
}

sub get_dbh {
    my ($self) = @_;

    my $cached_dbh = $self->{_dbh};
    $cached_dbh = eval {
        $cached_dbh
        and ref $cached_dbh
        and $cached_dbh->FETCH('Active')
        and $cached_dbh->ping()
        and $cached_dbh
    };

    if (! $cached_dbh) {
        my $new_dbh = $self->connect();
        $self->{_dbh} = $cached_dbh = $new_dbh;
    }

    return $cached_dbh;
}

sub create_sequence {
    my ($self, $name, $start_value) = @_;

    return unless defined $name && $name ne '';

    if (! defined $start_value || $start_value eq "") {
        $start_value = 1;
    }

    $name =~ s{\W}{}g;
    $start_value =~ s{\D}{}g;

    my $sql = <<SQL;
CREATE TABLE IF NOT EXISTS $name (
    id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    stub char(1) NOT NULL UNIQUE DEFAULT ''
) ENGINE=MyISAM AUTO_INCREMENT=$start_value CHARACTER SET='UTF8'
SQL
    my $created = 0;

    eval {
        my $dbh = $self->get_dbh();
        my $sth = $dbh->prepare($sql);
        $created = $sth->execute();
        $sth->finish();
        $created;
    } or do {
        Carp::croak("New sequence $name not created: $@");
    };

    return 1;
}

sub next_val {
    my ($self, $sequence) = @_;

    my $dbh = $self->get_dbh();
    if (! $dbh) {
        Carp::croak("Can't get next value: $!");
    }

    $sequence =~ s{\W}{}g;

    my $ok = 0;
    my $tries = 3;
    my $sth;

    while (--$tries) {
        $sth = $dbh->prepare("REPLACE INTO $sequence (stub) VALUES ('a')");
        $ok = $sth->execute();
        if (! $ok) {
            warn("Attempt to get next value from sequence '$sequence' FAILED: $!");
        }
        last if $ok;
    }

    if (! $ok) {
        Carp::croak("PANIC: Couldn't get next value from sequence '$sequence'");
    }

    my $dbname = $self->{_dbname};
    my ($next_val) = $dbh->last_insert_id(undef, $dbname, $sequence, 'id');
    $sth->finish() if $sth;

    return $next_val;
}

1;
