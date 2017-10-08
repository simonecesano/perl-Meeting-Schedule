use Test::More 'no_plan';
use Data::Dump qw/dump/;

$\ = "\n";

require_ok( 'Meeting::Person' );

use Meeting::Util qw/free_at find_slots/;
use Meeting::Person;

my $a = {
	 email => "some.body\@acme.com",
	 end => "2017-09-07T00:00:00",
	 freebusy => "0200201000000102011112010021020020200201212001022020102202010000202200000010202200100001121102110010",
	 start => "2017-08-10T00:00:00",
};


my $p = Meeting::Person->new($a);

isa_ok($p, 'Meeting::Person');

ok($p->freebusy_array->[0] == 0, 'freebusy');

# print join ',', split '', $p->freebusy;
print join ',', $p->slots(4, 1, 1);
my $i;
print join ',', map { join '=', $i++, $_ } split '', $p->freebusy;

# $p->slots($lenght, $tentative, $all);

is_deeply([ $p->slots(1, 0, 1) ], [0,2,3,5,7,8,9,10,11,12,14,16,22,24,25,28,30,31,33,35,36,38,43,44,46,49,51,53,56,58,60,61,62,63,65,68,69,70,71,72,73,75,77,80,81,83,84,85,86,92,96,97,99]);
is_deeply([ $p->slots(1) ], [22,24,25,28,30,31,33,68,69,70,71,72,73,75,77,80,81]);

is_deeply([ $p->slots(3, 0, 1) ], [7,8,9,10,60,61,68,69,70,71,83,84]);
is_deeply([ $p->slots(3, 1, 0) ], [18,22,23,68,69,70,71,72,73,80,81,82]);

is_deeply([ $p->slots(4, 1, 1) ], [5,6,7,8,9,10,11,16,17,22,43,58,59,60,68,69,70,71,72,80,81,82,83,84,85,94,95,96]);
