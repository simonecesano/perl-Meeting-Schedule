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

    sub free_slots($freebusy, $start, $interval, $tentative) = @_;

Returns a list of start and end times of free slots for a free/busy string

    my $dt = DateTime->new( year => 2017, month => 10, day => 9, hour => 9, minute => 0, second => 0, time_zone => 'Europe/Berlin', );

    free_slots('0001110011100001001000111001', $dt, 30, 0)

    #   2017-10-09T09:00:00 - 2017-10-09T10:30:00
    #   2017-10-09T12:00:00 - 2017-10-09T13:00:00
    #   2017-10-09T14:30:00 - 2017-10-09T16:30:00
    #   2017-10-09T17:00:00 - 2017-10-09T18:00:00
    #   2017-10-09T18:30:00 - 2017-10-09T20:00:00
    #   2017-10-09T21:30:00 - 2017-10-09T22:30:00
	
### slot\_to\_start

    sub slot_to_start($slot, $start, $interval, $duration);

Returns the start time for a given slot and interval

    my $dt = DateTime->new( year => 2017, month => 10, day => 9, hour => 9, minute => 0, second => 0, time_zone => 'Europe/Berlin', );

    slot_to_start(3, $dt, 30)
    #   2017-10-09T10:30:00

    slot_to_start(5, $dt, 30, 4)
    #   2017-10-09T13:30:00

### recurrence

Returns a free/busy string for given recurring working hours or busy times

### intersection(\\@@)

    intersection(\@@)();

Returns the intersection of two arrays - i.e.: the elements that are in both arrays.
