package Meeting::Util;

require Exporter;

use POSIX qw(floor ceil);
use List::Util qw/reduce/;
use List::MoreUtils qw/pairwise any none/;

use DateTime;
use DateTime::Event::Recurrence;

use strict;

use Mojo::JSON qw(decode_json encode_json);

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(find_slots free_at intersection busy_string all_busy slot_to_start recurrence free_slots);

sub intersection(\@@) {
	my $s = shift;
	my %h; @h{@_} = map { 1 } @_;
	return grep { $h{$_} } @$s
}

sub find_slots {
    my ($freebusy, $length, $tentative) = @_;

    my $regex = sprintf "(?=(%s){%d,%d})", ($tentative ? '0|1' : '0'), $length, $length;

    my @ret;
    while ($freebusy =~ /$regex/g) { push @ret, $-[0] }
    return @ret
}

sub free_at {
    my ($freebusy, $at, $length, $tentative) = @_;

    my $regex = sprintf '^\d{%d,%d}%s{%d,%d}', $at, $at, ($tentative ? '[0-1]' : '0'), $length, $length;

    return $freebusy =~ /$regex/
}

sub busy_string {
    my ($s, $e, $f, $interval, $length) = @_;

    my $fsl = floor($s->subtract_datetime($f)->in_units('minutes') / $interval);
    my $bel = ceil($e->subtract_datetime($f)->in_units('minutes') / $interval);

    my $fsl = floor(($s->epoch - $f->epoch) / ( $interval * 60 ));
    my $bel = ceil(($e->epoch - $f->epoch) / ( $interval * 60 ));
    
    return substr((join  '', ('0' x $fsl),  ('2' x ($bel - $fsl)), ('0' x ($length - $bel))), 0, $length);
}

sub all_busy { reduce { $a | $b } @_ }

sub slot_to_start {
    my ($slot, $start, $interval, $duration) = @_;
    return $start->clone->add(minutes => $interval * ($slot + $duration))
}

sub validate {
    my $h = shift;
    my ($freq) = keys %{$h};

    my $tz = delete $h->{$freq}->{time_zone};
    unless ( exists $h->{$freq}->{start} ) { $h->{$freq}->{start} = delete $h->{$freq} }

    my $f = $h->{$freq};
    if ($f->{start}->{days}
	&& !$f->{end}->{days}) {
	if (none { $f->{end}->{$_} } qw/minutes hours seconds/ ) {
	    $f->{end}->{days} = [ map { 1 + ($_ % 7) } @{$f->{start}->{days}}]
	} else {
	    $f->{end}->{days} = [ @{$f->{start}->{days}} ]
	}
    }
    return ($freq, $tz, $f);
}

sub recurrence {
    my $h = shift;
    my ($start, $interval, $length) = @_;
    my $end = $start->clone->add(minutes => $interval * $length);

    my ($freq, $tz, $f) = validate($h);
    my ($sign, $sub) = $freq =~ /([+-]*)(.+)/;

    my $recurrence;

    for (qw/end start/) {
	$recurrence->{$_} = DateTime::Event::Recurrence->$sub( %{$f->{$_}} );
	$recurrence->{$_}->set_time_zone( $tz ) if $tz;
    }

    my @starts = $recurrence->{start}->as_list( start => $start, end => $end );
    my @ends   = $recurrence->{end}->as_list( start => $starts[0], end => $end );

    if ($ends[0] <= $starts[0]) { unshift @starts, $start };
    if ((scalar @ends) < (scalar @starts)) { push @ends, $end }
    
    my $freebusy = all_busy(map {
	busy_string($_->[0], $_->[1], $start, $interval, $length)
    } pairwise { [$a, $b ] } @starts, @ends);

    unless ($sign eq '-') { $freebusy =~ tr/01234/20000/ }

    return $freebusy;
}

sub free_slots {
    my ($freebusy, $start, $interval, $tentative) = @_;
    my $regex = sprintf "(%s+)", ($tentative ? '0|1' : '0');
    my @ret;
    while ($freebusy =~ /$regex/g) { push @ret, [$-[0], length($1)] }
    return map {
	[ slot_to_start($_->[0], $start, $interval), slot_to_start($_->[0], $start, $interval, $_->[1]) ]
    } @ret
}

1;

=head1 NAME

Meeting::Util


=head1 REQUIRES

L<List::Util> 

L<POSIX> 


=head1 METHODS

=head2 all_busy

 all_busy(@freebusy_strings);

Given a list of free/busy strings, returns one combining them all. The list will have free slots where all the free/busy strings show free 

  all_busy( '00011100111000', 
            '01001000111001');

  # returns '01011100111001'

=head2 busy_string

 busy_string($start_time_of_slot, $end_time_of_slot, $start_time_of_string, $interval, $length_of_string);

Returns a free/busy string given the start and end of a busy slot, the start time of the free/busy string, the detail interval and the length 

  my $s = DateTime->new(year => 2017, month => 9, day => 2, hour => 16, minute => 0, second => 0);
  my $e = DateTime->new(year => 2017, month => 9, day => 2, hour => 17, minute => 30, second => 0);
  my $f = DateTime->new(year => 2017, month => 9, day => 2, minute => 0, hour => 0, second => 0);

  busy_string($s, $e, $f, 30, 48 * 2);

  # returns '000000000000000000000000000000001110000000000000000000000000000000000000000000000000000000000000'

=head2 find_slots

 find_slots($freebusy, $length, $tentative);

Returns a list of free slots of a given length; if $tentative is true, it treats tentatively busy slots as free

  find_slots('00011100111', 2);
  # returns (0, 1, 6)

  find_slots('00011100111', 1);
  # returns (0, 1, 2, 6, 7)

  find_slots('00011100111', 3);
  # returns (0)

=head2 free_at

 free_at($freebusy, $at, $length, $tentative);

Returns whether the free/busy string shows free at a given point and for a given number of slots; if $tentative is true, it treats tentatively busy slots as free 

  free_at('00011100111', 3);
  # returns true

  free_at('00011100111', 3, 2);
  # returns false

  free_at('00011100111', 6, 2);
  # returns true

=head2 free_slots

Returns a list of start and end times of free slots for a free/busy string

=head2 slot_to_start

Returns the start time for a given slot and interval

=head2 recurrence

Returns a free/busy string for given recurring working hours or busy times

=head2 intersection(\@@)

 intersection(\@@)();

Returns the intersection of two arrays - i.e.: the elements that are in both arrays.

=cut

