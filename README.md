# perl-Meeting-Schedule #

## Meeting::Util

### all\_busy

    all_busy(@freebusy_strings);

Given a list of free/busy strings, returns one combining them all. The list will have free slots where all the free/busy strings show free 

    all_busy( '00011100111000', 
              '01001000111001');

    # returns '01011100111001'

### busy\_string

    busy_string($start_time_of_slot, $end_time_of_slot, $start_time_of_string, $interval, $length_of_string);

Returns a free/busy string given the start and end of a busy slot, the start time of the free/busy string, the detail interval and the length 

    my $s = DateTime->new(year => 2017, month => 9, day => 2, hour => 16, minute => 0, second => 0);
    my $e = DateTime->new(year => 2017, month => 9, day => 2, hour => 17, minute => 30, second => 0);
    my $f = DateTime->new(year => 2017, month => 9, day => 2, minute => 0, hour => 0, second => 0);

    busy_string($s, $e, $f, 30, 48 * 2);

    # returns '000000000000000000000000000000001110000000000000000000000000000000000000000000000000000000000000'

### find\_slots

    find_slots($freebusy, $length, $tentative);

Returns a list of free slots of a given length; if $tentative is true, it treats tentatively busy slots as free

    find_slots('00011100111', 2);
    # returns (0, 1, 6)

    find_slots('00011100111', 1);
    # returns (0, 1, 2, 6, 7)

    find_slots('00011100111', 3);
    # returns (0)

### free\_at

    free_at($freebusy, $at, $length, $tentative);

Returns whether the free/busy string shows free at a given point and for a given number of slots; if $tentative is true, it treats tentatively busy slots as free 

    free_at('00011100111', 3);
    # returns true

    free_at('00011100111', 3, 2);
    # returns false

    free_at('00011100111', 6, 2);
    # returns true

### free\_slots

Returns a list of start and end times of free slots for a free/busy string

### slot\_to\_start

Returns the start time for a given slot and interval

### recurrence

Returns a free/busy string for given recurring working hours or busy times

### intersection(\\@@)

    intersection(\@@)();

Returns the intersection of two arrays - i.e.: the elements that are in both arrays.
