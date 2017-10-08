use Test::More 'no_plan';
use Data::Dump qw/dump/;

$\ = "\n";

require_ok( 'Meeting::Util' );

use Meeting::Util qw/free_at find_slots/;

# is_deeply([ match_positions('(?=000)', '0011000100001000') ], [4, 8, 9, 13], 'match_positions');

is_deeply([ find_slots('0011000100001000', 3) ], [4, 8, 9, 13], 'find_slots');
is_deeply([ find_slots('0011002111001200', 3, 1) ], [0 .. 3, 7 .. 10], 'find_slots');
is_deeply([ find_slots('0011002111001200', 4) ], [], 'find_slots');
is_deeply([ find_slots('0011002111001200', 4, 1) ], [qw/0 1 2 7 8 9/], 'find_slots');

ok( free_at('0011002111001200', 0, 2) == 1, 'free_at');
ok( free_at('0011002111001200', 3, 3) != 1, 'free_at');
ok( free_at('0011002111001200', 3, 3, 1) == 1, 'free_at');
ok( free_at('0011002111001200', 5, 4, 1) != 1, 'free_at');

ok( free_at('0011002111001200', 0, 3, 1) == 1, 'free_at');
ok( free_at('0011002111001200', 6, 3, 1) != 1, 'free_at');
