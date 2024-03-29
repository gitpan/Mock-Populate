package Mock::Populate;
BEGIN {
  $Mock::Populate::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: Mock data creation

our $VERSION = '0.0901';

use strict;
use warnings;

use constant NDATA => 10;
use constant PREC  => 2;
use constant DOF   => 2;
use constant SIZE  => 8;

use Data::SimplePassword;
use Date::Range;
use Date::Simple qw(date today);
use Image::Dot;
use List::Util qw(shuffle);
use Mock::Person;
use Statistics::Distributions;
use Text::Password::Pronounceable;
use Text::Unidecode;
use Time::Local;


sub date_ranger {
    my %args = @_;
    # Set defaults.
    $args{start} ||= '2001-01-01';
    $args{end}   ||= today();
    $args{N}     ||= NDATA;

    # Convert the dates into a range.
    my $date1 = date($args{start});
    my $date2 = date($args{end});
    my $range = Date::Range->new($date1, $date2);

    # Declare the number of days in the range.
    my $offset = 0;

    # Bucket for our result list.
    my @results;

    for(1 .. $args{N}) {
        # Get a random number of days in the range.
        $offset = int(rand $range->length);

        # Save the stringified start date plus the offest.
        my $date = $date1 + $offset;
        push @results, "$date";
    }

    return \@results;
}


sub date_modifier {
    # Get the number of days in the future and the date list.
    my ($offset, @dates) = @_;

    # Bucket for our result list.
    my @results;

    for my $date (@dates) {
        # Cast the current date string as an object.
        my $current = date($date);

        # Get a random number of days in the future.
        my $m = int(rand $offset) + 1;

        # Save the stringified date plus the offest.
        $date = $current + $m;
        push @results, "$date";
    }

    return \@results;
}


sub time_ranger {
    my %args = @_;
    # Set defaults.
    $args{stamp} ||= 1;
    $args{start} ||= '00:00:00';
    $args{end}   ||= '';
    $args{N}     ||= NDATA;

    # Split the :-separated times.
    my @start = split ':', $args{start};
    my @end   = $args{end} ? split(':', $args{end}) : _now();
    #warn "S->E: @start -> @end\n";

    # Compute the number of seconds between start and end.
    my $start_time = timegm(@start[2, 1, 0], (localtime(time))[3, 4, 5]);
    my $end_time   = timegm(@end[2, 1, 0], (localtime(time))[3, 4, 5]);
    my $range = $end_time - $start_time;
    #warn "R: $end_time (@end) - $start_time (@start) = $range\n";

    # Declare the number of seconds.
    my $offset = 0;

    # Bucket for our result list.
    my @results;

    # Generate a time, N times.
    for(1 .. $args{N}) {
        # Get a random number of seconds in the range.
        $offset = int(rand $range);

        # Print the start time plus the offest seconds.
        if ($args{stamp}) {
            # In HH:MM::SS format.
            my $time = scalar localtime($start_time + $offset);
            push @results, (split / /, $time)[3];
        }
        else {
            # As a number of seconds from the "epoc."
            push @results, $start_time + $offset;
        }
    }

    return \@results;
}

sub _now { # Return hour, minute, second.
    return (localtime(time))[2, 1, 0];
}


sub number_ranger {
    my %args = @_;
    # Set defaults.
    $args{start}  ||= 0;
    $args{end}    ||= NDATA;
    $args{prec}   ||= PREC;
    $args{random} ||= 1;
    $args{N}      ||= NDATA;

    # Bucket for our result list.
    my @results;

    # Do we want random numbers?
    if ($args{random}) {
        # Roll!
        for(1 .. $args{N}) {
            # Get our random candidate.
            my $x = rand($args{end});
            # Make sure it is above the start value.
            while ($x < $args{start}) {
                $x = rand($args{end});
            }
            push @results, $x;
        }
    }
    else {
        # Use a simple sequence of integers.
        @results = ($args{start} .. $args{end});
    }

    return \@results;
}


sub name_ranger {
    my %args = @_;
    # Set defaults.
    $args{gender}  ||= 0;
    $args{names}   ||= 2;
    $args{country} ||= 'us';
    $args{N}       ||= NDATA;

    # Bucket for our result list.
    my @results;

    # Roll!
    for my $i (1 .. $args{N}) {
        # Get our random person.
        my $p = '';
        # If gender is 'both' alternate male-female.
        # Or if gender is not 'male' then ...female!
        if (($args{gender} eq 'b' && $i % 2) || $args{gender} eq 'f') {
            $p = Mock::Person::name(sex => 'female', country => $args{country});
        }
        else {
            $p = Mock::Person::name(sex => 'male', country => $args{country});
        }
        # Only use the requested number of names.
        my @names = split / /, $p;
        my $name = '';
        if ($args{names} == 1) {
            push @results, $names[-1];
        }
        elsif ($args{names} == 2) {
            push @results, "@names[0,-1]";
        }
        else {
            push @results, $p;
        }
    }

    return \@results;
}


sub email_modifier {
    my @people = @_;

    # Bucket for our results.
    my @results = ();

    # Generate email addresses if requested.
    my @tld = qw( com net org edu );

    for my $p (@people) {
        # Break up the name.
        my @name = split / /, $p;

        # Turn any unicode characters into something ascii.
        $_ = unidecode($_) for @name;

        # Add an email address for the person.
        my $email = lc($name[0]);
        $email .= '.'. lc($name[-1]) if @name > 1;
        $email .= '@example.' . $tld[rand @tld];
        push @results, $email;
    }

    return \@results;
}


sub distributor {
    my %args = @_;
    # Set defaults.
    $args{type} ||= 'u';
    $args{prec} ||= PREC;
    $args{dof}  ||= DOF;
    $args{N}    ||= NDATA;

    # Separate numerator/denominator for F degs-of-freedm.
    my $e = 1;
    ($args{dof}, $e) = split(/\//, $args{dof}) if $args{type} eq 'f';

    # Bucket for our result list.
    my @results;

    # Roll!
    for(1 .. $args{N}) {
        # Select distribution.
        if ($args{type} eq 'c') {
            # Chi-squared
            push @results, Statistics::Distributions::chisqrdistr($args{dof}, rand);
        }
        elsif ($args{type} eq 's') {
            # Student's T
            push @results, Statistics::Distributions::tdistr($args{dof}, rand);
        }
        elsif ($args{type} eq 'f') {
            # F distribution
            push @results, Statistics::Distributions::fdistr($args{dof}, $e, rand);
        }
        else {
            # Normal
            push @results, Statistics::Distributions::udistr(rand);
        }
    }

    return \@results;
}


sub shuffler {
    # Get the desired number of data-points.
    my $n = defined $_[0] ? shift : 9;
    # Get the items to shuffle.
    my @items = @_ ? @_ : ('a' .. 'j');
    return [ shuffle(@items) ];
}


sub string_ranger {
    my %args = @_;
    # Set defaults.
    $args{length} ||= SIZE;
    $args{type}   ||= 'default';
    $args{N}      ||= NDATA;

    # Declare a pw instance.
    my $sp = Data::SimplePassword->new;

    # Declare the types (lifted directly from rndpassword).
    my $chars = {
        default => [ 0..9, 'a'..'z', 'A'..'Z' ],
        ascii   => [ map { sprintf "%c", $_ } 33 .. 126 ],
        base64  => [ 0..9, 'a'..'z', 'A'..'Z', qw(+ /) ],
        path    => [ 0..9, 'a'..'z', 'A'..'Z', qw(. /) ],
        simple  => [ 0..9, 'a'..'z' ],
        alpha   => [ 'a'..'z' ],
        digit   => [ 0..9 ],
        binary  => [ qw(0 1) ],
        morse   => [ qw(. -) ],
        hex     => [ 0..9, 'a'..'f' ],
        pron    => [],
    };
    # Set the chars based on the given type.
    $sp->chars( @{ $chars->{$args{type}} } );

    # Declare a bucket for our results.
    my @results = ();

    # Roll!
    for(1 .. $args{N}) {
        if ($args{type} eq 'pron') {
            push @results, Text::Password::Pronounceable->generate(
                $args{length}, $args{length});
        }
        else {
            push @results, $sp->make_password($args{length});
        }
    }

    return \@results;
}


sub image_ranger {
    my %args = @_;
    # Set defaults.
    $args{size} ||= SIZE;
    $args{N}    ||= NDATA;

    # Declare a bucket for our results.
    my @results = ();

    # Start with a 1x1 pixel image.
    my $img = dot_PNG_RGB(0, 0, 0);

    # XXX This is naive and sad:
    # Pull-apart the image data.
    (my $head = $img) =~ s/^(.*?IDAT).*$/$1/ms;
    (my $tail = $img) =~ s/^.*?(IEND.*)$/$1/ms;
    $img =~ s/^.*?IDAT(.*?)IEND.*$/$1/ms;

    for (1 .. $args{N}) {
        # Increase the byte size (not dimension).
        my $i = $head . ($img x int(rand $args{size})) . $tail;
        #warn "L: ",length($i), "\n";

        # Save the result.
        push @results, $i;
    }

    return \@results;
}


sub collate {
    # Accept any number of columns.
    my @columns = @_;

    # Make a copy of the columns to peel off.
    my @lists = @columns;

    # Declare the bucket for our arrayrefs.
    my @results = ();

    # Add each list item to rows of collated.
    for my $list (@columns) {
        for my $i (0 .. @$list - 1) {
            push @{ $results[$i] }, $list->[$i];
        }
    }

    return \@results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Populate - Mock data creation

=head1 VERSION

version 0.0901

=head1 SYNOPSIS

  use Mock::Populate;
  # * Call each function below with Mock::Populate::foo(...
  $ids    = number_ranger(start => 1, end => 1001, prec => 0, random => 0, N => $n);
  $money  = number_ranger(start => 1000, end => 5000, prec => 2, random => 1, N => $n);
  $create = date_ranger(start => '1900-01-01', end => '2020-12-31', N => $n);
  $modify = date_modifier($offset, @$create);
  $times  = time_ranger(stamp => 1, start => '01:02:03' end =>'23:59:59', N => $n);
  $people = name_ranger(gender => 'b', names => 2, country => 'us', N => $n);
  $email  = email_ranger(@$people);
  $shuff  = shuffler($n, qw(foo bar baz goo ber buz));
  $stats  = distributor(type => 'u', prec => 4, dof => 2, N => $n);
  $string = string_ranger(length => 32, type => 'base64', N => $n);
  $imgs   = image_ranger(size => 10, N => $n);  # *size is density, not pixel dimension
  $coll   = collate($ids, $people, $email, $create, $times, $modify, $times);

=head1 DESCRIPTION

This is a set of functions for mock data creation.

No functions are exported, so use the entire C<Mock::Populate::*> namespace when
calling each.

Each function produces a list of elements that can be used as database columns.
The handy C<collate()> function takes these columns and returns a list of
(arrayref) rows.  This can then be processed into CSV, JSON, etc.  It can also
be directly inserted into your favorite database, with your favorite perl ORM.

=head1 FUNCTIONS

=head2 date_ranger()

  $results = date_ranger(start => $start, end => $end, N => $n);

Return a list of N random dates within a range.  The start and end dates and
desired number of data-points arguments are all optional.  The defaults are:

  start: 2000-01-01
  end: today (computed if not given)
  N: 10

The dates must be given as B<YYYY-MM-DD> strings.

=head2 date_modifier()

  $modify = date_modifier($offset, @$dates);

Returns a new list of random future dates, based on the offset, and respective
to each given date.

=head2 time_ranger()

  $results = time_ranger(
    stamp => $stamp, start => $start, end => $end,
    N => $n);

Return a list of N random times within a range.  The start and end times and
desired number of data-points arguments are all optional.  The defaults are:

  stamp: 1 (boolean)
  start: 00-00-00
  end: now (computed if not given)
  N: 10

The times must be given as B<HH-MM-SS> strings.

=head2 number_ranger()

  $results = number_ranger(
    start => $start, end => $end,
    prec => $prec, random => $random,
    N => $n)

Return a list of N random numbers within a range.  The start, end, precision,
whether we want random or sequential numbers and desired number of data-points
arguments are all optional.  The defaults are:

  start: 0
  end: 9
  precision: 2
  random: 1
  N: 10

=head2 name_ranger()

  $results = name_ranger(
    gender => $gender, names => $names, country => $country,
    N => $n)

Return a list of N random person names.  The gender, number of names and
desired number of data-points arguments are all optional.  The defaults are:

  gender: b (options: both, female, male)
  names: 2 (first, last)
  country: us
  N: 10

=head2 email_modifier()

  $results = email_modifier(@people)
  # first.last@example.{com,net,org,edu}

Return a list of N email addresses based on a list of given names.

=head2 distributor()

  $results = distributor(type => $type, prec => $prec, dof => $dof, N => $n)

Return a list of N distribution values.  The type, precision, degrees-of-freedom
and desired number of data-points arguments are optional.  The defaults are:

  type: u (normal)
  precision: 2
  degrees-of-freedom: 2
  N: 10

=head3 Types

This function uses single letter identifiers:

  u: Normal distribution (default)
  c: Chi-squared distribution
  s: Student's T distribution
  f: F distribution

=head3 Degrees of freedom

Given the type, this function accepts the following:

  c: A single integer
  s: A single integer
  f: A fraction string of the form 'N/D' (default 2/1)

=head2 shuffler()

  $results = shuffler($n, @items)

Return a shuffled list of B<$n> items.  The items and number of data-points
arguments are optional.  The defaults are:

  n: 10
  items: a b c d e f g h i j

=head2 string_ranger()

  $results = string_ranger(type => $type, length => $length, N => $n)

Return a list of N strings.  The strings and number of data-points
arguments are optional.  The defaults are:

  type: default
  length: 8
  N: 10

* This function is nearly identical to the L<Data::SimplePassword>
C<rndpassword> program, but allows you to generate a finite number of results.

=head3 Types

  Types     Output sample     Character set
  ___________________________________________________
  default   0xaVbi3O2Lz8E69s  0..9 a..z A..Z
  ascii     n:.T<Gr!,e*[k=eu  visible ascii
  base64    PC2gb5/8+fBDuw+d  0..9 a..z A..Z / +
  path      PC2gb5/8.fBDuw.d  0..9 a..z A..Z / .
  simple    xek4imbjcmctsxd3  0..9 a..z
  hex       89504e470d0a1a0a  0..9 a..f
  alpha     femvifzscyvvlwvn  a..z
  pron      werbucedicaremoz  a..z but pronounceable!
  digit     7563919623282657  0..9
  binary    1001011110000101
  morse     -.--...-.--.-..-

=head2 image_ranger()

  $results = image_ranger(size => $size, N => $n)

Return a list of N 1x1 pixel images of varying byte sizes (not image dimension).
The byte size and number of data-points are both optional.

The defaults are:

  N: 10
  size: 8

=head2 collate()

  $rows = collate(@columns)

Return a list of lists representing a 2D table of rows, given the lists
provided, with each member added to a row, respectively.

=head1 SEE ALSO

L<Data::SimplePassword>

L<Date::Range>

L<Date::Simple>

L<Image::Dot>

L<List::Util>

L<Mock::Person>

L<Statistics::Distributions>

L<Text::Password::Pronounceable>

L<Text::Unidecode>

L<Time::Local>

L<Data::Random> does nearly the exact same thing. Whoops!

=head1 TO DO

Implement dirty-data randomizing.

  unexpected formats: iso-8859-1, utf-16, windows codepage,
  BOM (byte order marker),
  broken unicode,
  garbled binary,
  \r and \n variations,
  commas or $ in currencies ("format fuckups"),
  bad JSON,
  broken XML,
  bad ' and " in CSV,
  statistical outliers,
  time-series drops and spikes,
  duplicate data,
  missing data,
  truncated data,

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
