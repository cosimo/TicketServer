Tickets server
=========================

A sample implementation hacked together in a couple of hours
in Perl + MySQL of the Flickr tickets server, as explained
in this [blog post](http://code.flickr.com/blog/2010/02/08/ticket-servers-distributed-unique-primary-keys-on-the-cheap/).

Assumptions
-----------

* MySQL 5.1+ is installed locally, listening on `localhost:3306`
* Perl 5.8+ is installed, along with DBI (`apt-get install libdbi-perl`)

How to use this
---------------

* Basic sql schema is found in `sql/tickets.sql`
* To test basic sanity, after setting up the db, run: `prove -Ilib -v`
* To stress test the tickets db, run: `perl bin/stress.pl`

Contacts
--------

Email:   cosimo@cpan.org
Twitter: @cstrep

