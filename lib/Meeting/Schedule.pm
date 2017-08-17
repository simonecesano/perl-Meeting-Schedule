package Meeting::Schedule;

use Mojo::Base -base;
use List::Util qw(shuffle);
use List::MoreUtils qw(first_index uniq indexes);
use Data::Dump qw/dump/;

use DateTime;
use Memoize;

memoize(qw/period periods/);


# use DateTime::TimeZone::Europe::Berlin;

has 'people' => sub { [] };
has 'fills' => sub { {} };
has [qw/working_slots meeting_slots periods/] => sub { [] };

has [qw/length interval/];

has [qw/start end/] => sub { DateTime->new };



sub new {
	my $self = shift->SUPER::new(@_);

	my ($start_time, $end_time) = (9, 17);
	my $interval = $self->interval;
	my $start = $self->start;
	
	my @periods =  map { $start->clone->add(minutes => $interval * $_) } (0..($self->length - 1));
	
	my @s = indexes { my $s = $_->hour;
			  my $e = $_->clone->add(minutes => $interval)->hour;
			  return
			      $_->day_of_week <= 5
			      && ($s >= $start_time)
			      && ($e <= $end_time)
			      && ($s <= $e)
		      } @periods;

	$self->working_slots(\@s);
	$self->periods(\@periods);
	return $self;
}

sub period { shift->periods->[shift] };

sub add_person {
	my $self = shift;
	my $person = shift;
	# my $rank = $person->rank;

	$person->schedule($self);

	push @{$self->people}, $person;

	if ((scalar @{$self->people}) == 1) { $self->people->[0]->me(1) } 

	# sort after inserting
	my $p = $#{$self->people};
	if ((scalar @{$self->people}) > 2) {
	    $self->people([ $self->people->[0], (map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { $_ = [$_, $_->rank ]} @{$self->people}[1..$p]) ]);
	}
};

sub people_available_at {
	my $self = shift;
	my $slot = shift;

	my @people = @{$self->people};

	return grep { $_->freebusy->[$slot] == 0 } @people;
}

sub used_slots {
	my $self = shift;
	return sort { $a <=> $b } uniq grep { defined $_ } map { $_->slot } @{$self->people};
}

sub fill_quota {
	my $self = shift;
	my $slot = shift;
	
	if (defined $slot) { return $self->fills->{$slot} || 0 } else { return %{$self->fills} }
}

sub people_in_slot {
    my $self = shift;
    my $slot = shift;

    return grep { defined $_->slot && $_->slot == $slot } @{$self->people};
}

sub unscheduled { grep {!defined $_->slot } @{shift->people} }

sub schedule {
    my ($self, %opts) = @_;

    my $i;
    my $q = $opts{max_meeting_size} || 1;
    
    for my $p (@{$self->people}) {
	if ($i++ > 1) {
	    # assign to earliest already used slot
	    for ($self->used_slots) {
		if ($p->freebusy->[$_] == 0 && $self->fill_quota($_) < $q) {
		    $p->slot($_);
		    last;
		}
	    }
	    # assign to earliest slot
	    for ($p->slots) {
		if ($self->fill_quota($_) < $q) {
		    $p->slot($_) unless defined $p->slot;
		    last;
		}
	    }
	} else {
	    $p->slot($p->slots->[0]);
	}
    }

    if ($opts{pack}) {
	my @slots = $self->used_slots;
	for my $slot (@slots) {
	    next unless $self->fill_quota($slot) < $q;
	    for ($self->people_in_slot($slot)) {
		if (my @can = $_->can_later(@slots)) {
		    $_->slot($can[0]);
		}
	    }
	}
    }

    # if max_meetings, always pack, then sort meetings by size, and eliminate tail
    # if max_meetings is set and max_meeting_size is not set, max_meeting_size should be set to number of people
    if (my $l = $opts{cancel_if_less_than}) {
	my @slots = $self->used_slots;
	for my $slot (@slots) {
	    next unless $self->fill_quota($slot) < $l;
	    for ($self->people_in_slot($slot)) {
		$_->slot(undef);
	    }
	}

    }
}

1;
