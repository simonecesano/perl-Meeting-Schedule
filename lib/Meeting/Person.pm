package Meeting::Person;

use Mojo::Base -base;
use Data::Dump qw/dump/;
use List::MoreUtils qw(any uniq indexes);

has [qw/freebusy email _slot schedule me/];
has interval => 30;
has [qw/_periods _working_slots/] => sub { [] };

use DateTime;
use Memoize;

memoize(qw/slots working_slots periods/);

sub slot {
	my $self = shift;
	if (@_) {
	    my $slot = shift;
	    if (defined $slot) {
		if ($self->schedule) {
		    $self->schedule->fills->{$self->_slot}-- if defined $self->_slot;
		    $self->schedule->fills->{$slot}++;
		}
		$self->_slot($slot);
	    } else {
		if ($self->schedule) { $self->schedule->fills->{$self->_slot}-- if defined $self->_slot }
		$self->_slot(undef);
	    }
	}
	return $self->_slot;
}

sub intersection(\@@) {
	my $s = shift;
	my %h; @h{@_} = map { 1 } @_;
	return grep { $h{$_} } @$s
}

sub periods {
	my $self = shift;
	my $interval = 30;
	my $i;
	return map { $self->start->clone->add(minutes => $self->interval * $i++) } @{$self->freebusy}
}

sub working_slots {
	my $self = shift;

	return @{$self->schedule->working_slots} if (defined $self->schedule);
	
	my ($start_time, $end_time) = (9, 17);
	my $start;
	my $interval = $self->interval;
	my @periods = $self->periods;

	my @s = indexes { my $s = $_->hour;
			  my $e = $_->clone->add(minutes => $interval)->hour;
			  return ($s >= $start_time) && ($e <= $end_time) && ($s <= $e) } @periods;
}


sub slots {
	# returns the indexes of slots where the person is free
	# and the meeting requester is also free
	my $self = shift;
	my $all = shift;
	
	my @s = indexes { $_ == 0 } @{$self->freebusy};

	if (!$self->me && $self->schedule && !$all) {
	    my @r = $self->schedule->people->[0]->slots;
	    @s = intersection(@s, @r);
	}
	if (!$all) {
	    my @r = $self->working_slots;
	    @s = intersection(@s, @r);
	}
	return wantarray ? @s : \@s;
}

sub available_at { return shift->freebusy->[shift] == 0 }

sub rank { my @s = shift->slots; return scalar @s }

sub can_later {
	my $self = shift;
	my @later_slots = @_;

	my $slot = $self->slot || 0;
	my @available_slots = $self->slots;
	
	return intersection(@available_slots, (grep { $_ > $slot } @later_slots));
}

1;
