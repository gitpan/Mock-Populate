use Test::More;

use_ok 'Mock::Populate';

# TODO Test contents for looks_like_a_number, etc, instead.
my @d = Mock::Populate::date_ranger();
is @d, 10, 'date_ranger';
my @t = Mock::Populate::time_ranger();
is @t, 10, 'time_ranger';
my @x = Mock::Populate::number_ranger();
is @x, 10, 'number_ranger';
@x = Mock::Populate::personify();
is @x, 10, 'personify';
@x = Mock::Populate::stats_distrib();
is @x, 10, 'stats_distrib';
@x = Mock::Populate::shuffler();
is @x, 10, 'shuffler';
@x = Mock::Populate::collate(\@d, \@t);
is @x, 10, 'collate';

done_testing();
