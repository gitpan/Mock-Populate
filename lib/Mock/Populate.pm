package Mock::Populate;
BEGIN {
  $Mock::Populate::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: Mock data creation

our $VERSION = '0.05';

use strict;
use warnings;

use Data::SimplePassword;
use Date::Range;
use Date::Simple qw(date today);
use Image::Dot;
use List::Util qw(shuffle);
use Mock::Person;
use Statistics::Distributions;
use Time::Local;


sub date_ranger {

    # Get start and end dates.
    my $d1 = shift || '2000-01-01';
    my $d2 = shift || today();
    my $n  = shift || 9;

    # Convert the dates into a range.
    my $date1 = date($d1);
    my $date2 = date($d2);
    my $range = Date::Range->new($date1, $date2);

    # Declare the number of days in the range.
    my $offset = 0;

    # Bucket for our result list.
    my @results;

    for(0 .. $n) {
        # Get a random number of days in the range.
        $offset = int(rand $range->length);

        # Save the stringified start date plus the offest.
        my $date = $date1 + $offset;
        push @results, "$date";
    }

    return @results;
}


sub time_ranger {
    # Do we want output in HH::MM:SS stamp or "seconds since unix epoc?"
    my $stamp = defined $_[0] ? shift : 1;
    # Get start and end times.
    my $start = shift || '00:00:00';
    my $end   = shift || '';
    # Set the desired number of data-points.
    my $n     = shift || 9;

    # Split the :-separated times.
    my @start = split ':', $start;
    my @end   = $end ? split(':', $end) : _now();
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
    for(0 .. $n) {
        # Get a random number of seconds in the range.
        $offset = int(rand $range);

        # Print the start time plus the offest seconds.
        if ($stamp) {
            # In HH:MM::SS format.
            my $time = scalar localtime($start_time + $offset);
            push @results, (split / /, $time)[3];
        }
        else {
            # As a number of seconds from the "epoc."
            push @results, $start_time + $offset;
        }
    }

    return @results;
}

sub _now { # Return hour, minute, second.
    return (localtime(time))[2, 1, 0];
}


sub number_ranger {

    # Bucket for our result list.
    my @results;

    # Get start and end numbers.
    my $i = defined $_[0] ? shift : 0;
    my $j = defined $_[0] ? shift : 9;
    # Get the decimal precision.
    my $p = defined $_[0] ? shift : 2;
    # Do we want random numbers?
    my $r = defined $_[0] ? shift : 0;
    # Get the number of data points desired.
    my $n = defined $_[0] ? shift : 9;

    # Do we want random numbers?
    if ($r) {
        # Roll!
        for(0 .. $n) {
            # Get our random candidate.
            my $x = rand($j);
            # Make sure it is above the start value.
            while ($x < $i) {
                $x = rand($j);
            }
            push @results, $x;
        }
    }
    else {
        # Use a simple sequence of integers.
        @results = ($i .. $j);
    }

    return @results;
}


sub personify {

    # Bucket for our result list.
    my @results;

    # Get gender. f: female, m: male, b: both
    my $g = defined $_[0] ? shift : 'b';
    # Get desired number of names.
    my $d = defined $_[0] ? shift : 2;
    # Get the country to use.
    my $c = defined $_[0] ? shift : 'us';
    # Get desired number of data-points.
    my $n = defined $_[0] ? shift : 9;

    # Roll!
    for my $i (0 .. $n) {
        # Get our random person.
        my $p = '';
        if (($g eq 'b' && $i % 2) || $g eq 'f') {
            $p = Mock::Person::name(sex => 'female', country => $c);
        }
        else {
            $p = Mock::Person::name(sex => 'male', country => $c);
        }
        # Only use the requested number of names.
        my @names = split / /, $p;
        my $name = '';
        if ($d == 1) {
            push @results, $names[-1];
        }
        elsif ($d == 2) {
            push @results, "@names[0,-1]";
        }
        else {
            push @results, $p;
        }
    }

    return @results;
}


sub stats_distrib {

    # Get type of distribution.
    my $p = defined $_[0] ? shift : 'u';
    # Get digits of precision.
    my $t = defined $_[0] ? shift : 2;
    # Get desired degrees of freedom for the ChiSq, StudentT & F.
    my $d = defined $_[0] ? shift : 2;
    # Get desired number of data-points.
    my $n = defined $_[0] ? shift : 9;

    # Separate numerator/denominator for F degs-of-freedm.
    my $e = 1;
    ($d, $e) = split(/\//, $d) if $t eq 'f';

    # Bucket for our result list.
    my @results;

    # Roll!
    for(0 .. $n) {
        # Select distribution.
        if ($t eq 'c') {
            # Chi-squared
            push @results, Statistics::Distributions::chisqrdistr($d, rand);
        }
        elsif ($t eq 's') {
            # Student's T
            push @results, Statistics::Distributions::tdistr($d, rand);
        }
        elsif ($t eq 'f') {
            # F distribution
            push @results, Statistics::Distributions::fdistr($d, $e, rand);
        }
        else {
            # Normal
            push @results, Statistics::Distributions::udistr(rand);
        }
    }

    return @results;
}


sub shuffler {
    # Get the desired number of data-points.
    my $n = defined $_[0] ? shift : 9;
    # Get the items to shuffle.
    my @items = @_ ? @_ : ('a' .. 'j');
    return shuffle(@items);
}


sub stringer {

    # Get desired password length.
    my $length = defined $_[0] ? shift : 8;
    # Get the type of char generator to use.
    my $type = defined $_[0] ? shift : 'default';
    # Get the number of data points desired.
    my $n = defined $_[0] ? shift : 9;

    # Declare a pw instance.
    my $sp = Data::SimplePassword->new;

    # Declare the types (lifted directly from rndpassword).
    my $chars = {
        default => [ 0..9, 'a'..'z', 'A'..'Z' ],
        ascii   => [ map { sprintf "%c", $_ } 33 .. 126 ],
        base64  => [ 0..9, 'a'..'z', 'A'..'Z', qw(+ /) ],
        b64     => [ 0..9, 'a'..'z', 'A'..'Z', qw(+ /) ],
        simple  => [ 0..9, 'a'..'z' ],
        alpha   => [ 'a'..'z' ],
        digit   => [ 0..9 ],
        binary  => [ 0, 1 ],
        morse   => [ qw(. -) ],
        hex     => [ 0..9, 'a'..'f' ],
    };
    # Set the chars based on the given type.
    $sp->chars( @{ $chars->{$type} } );

    # Declare a bucket for our results.
    my @results = ();

    # Roll!
    for(0 .. $n) {
        push @results, $sp->make_password($length);
    }

    return @results;
}


sub imager {
    # Get the number of data points desired.
    my $n = defined $_[0] ? shift : 9;

    # Declare a bucket for our results.
    my @results = ();

    # Generate images.
    for (0 .. $n) {
        push @results, dot_PNG_RGB(0, 0, 0);
    }

    return @results;
}


sub collate {
    # Accept any number of columns.
    my @columns = @_;

    # Make a copy of the columns to peel off.
    my @lists = @columns;

    # Declare the bucket for our arrayrefs.
    my @collated = ();

    # Add each list item to rows of collated.
    for my $list (@columns) {
        for my $i (0 .. @$list - 1) {
            push @{ $collated[$i] }, $list->[$i];
        }
    }
    return @collated;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Populate - Mock data creation

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Mock::Populate;
  @ids    = Mock::Populate::number_ranger(1, 1001, 0, 0, 1000);
  @dates  = Mock::Populate::date_ranger('1900-01-01', '2020-12-31', 1000);
  @times  = Mock::Populate::time_ranger(1, '01:02:03' '23:59:59', 1000);
  @nums   = Mock::Populate::number_ranger(1000, 5000, 2, 1, 1000);
  @people = Mock::Populate::personify('b', 2, 'us', 1000);
  @stats  = Mock::Populate::stats_distrib('u', 4, 2, 1000);
  @shuff  = Mock::Populate::shuffler(1000, qw(foo bar baz goo ber buz));
  @string = Mock::Populate::stringer(32, 'base64', 1000);
  @imgs   = Mock::Populate::imager(1000);
  @collated = Mock::Populate::collate(
    \@ids, \@dates, \@times, \@nums, \@people, \@stats, \@shuff, \@string);

=head1 DESCRIPTION

This is a set of functions for mock data creation.

Each function produces a list of elements that can be used as database columns.
The handy C<collate()> function takes these columns and returns a list of
(arrayref) rows.  This can then be processed into CSV, JSON, etc.  It can also
be directly inserted into your favorite database, with your favorite perl ORM.

=head1 NAME

Mock::Populate - Mock data creation

=head1 FUNCTIONS

=head2 date_ranger()

    @results = date_ranger($start, $end, $n);

Return a list of B<$n> random dates within a range.  The start and end dates and
desired number of data-points arguments are all optional.  The defaults are:

  start: 2000-01-01
  end: today (computed if not given)
  n: 10

The dates must be given as B<YYYY-MM-DD> strings.

=head2 time_ranger()

    @results = time_ranger($stamp, $start, $end, $n);

Return a list of B<$n> random times within a range.  The start and end times and
desired number of data-points arguments are all optional.  The defaults are:

  stamp: 1 (boolean)
  start: 00-00-00
  end: now (computed if not given)
  n: 10

The times must be given as B<HH-MM-SS> strings.

=head2 number_ranger()

  @results = number_ranger($start, $end, $prec, $random, $n)

Return a list of B<$n> random numbers within a range.  The start, end,
precision, whether we want random or sequential numbers and desired number of
data-points arguments are all optional.  The defaults are:

  start: 0
  end: 9
  precision: 2
  random: 0
  n: 10

=head2 personify()

  @results = personify($gender, $names, $country, $n)

Return a list of B<$n> random names.  The gender, number of names and desired
number of data-points arguments are all optional.  The defaults are:

  gender: both
  names: 2
  country: us
  n: 10

=head2 stats_distrib()

  @results = stats_distrib($type, $prec, $dof, $n)

Return a list of B<$n> distribution values.  The type, precision,
degrees-of-freedom and desired number of data-points arguments are optional.
The defaults are:

  type: u (normal)
  precision: 2
  degrees-of-freedom: 2
  n: 10

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

  @results = shuffler($n, @items)

Return a shuffled list of B<$n> items.  The items and number of data-points
arguments are optional.  The defaults are:

  n: 10
  items: a b c d e f g h i j

=head2 stringer()

  @results = stringer($n, @items)

Return a shuffled list of B<$n> items.  The items and number of data-points
arguments are optional.  The defaults are:

  type: default
  length: 8
  n: 10

* This function is nearly identical to the L<Data::SimplePassword>
C<rndpassword> program, but allows you to generate a finite number of results.

=head2 TYPES

  Types     output sample
  default   0xaVbi3O2Lz8E69s  # 0..9 a..z A..Z
  ascii     n:.T<Gr!,e*[k=eu  # visible ascii (a.k.a. spaghetti)
  base64    PC2gb5/8+fBDuw+d  # 0..9 a..z A..Z /+
  simple    xek4imbjcmctsxd3  # 0..9 a..z
  hex       89504e470d0a1a0a  # 0..9, 'a'..'f'
  alpha     femvifzscyvvlwvn  # a..z
  digit     7563919623282657  # 0..9
  binary    1001011110000101
  morse     -.--...-.--.-..-

=head2 imager()

  @results = imager($size, $n)

Return a list of B<$n> images.  The number of data-points is optional. Default:

  n: 10

=head2 collate()

  @rows = collate(@columns)

Return a list of lists representing a 2D table of rows, given the lists
provided, with each member added to a row, respectively.

=head1 SEE ALSO

L<Data::SimplePassword>

L<Date::Range>

L<Date::Simple>

L<List::Util>

L<Mock::Person>

L<Statistics::Distributions>

L<Time::Local>

L<Data::Random> does nearly the exact same thing. Whoops!

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
