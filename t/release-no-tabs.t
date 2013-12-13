
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/Date-Ranger',
    'bin/Number-Ranger',
    'bin/Passworder',
    'bin/Personify',
    'bin/Shuffler',
    'bin/Stats-Distrib',
    'bin/Time-Ranger',
    'lib/Mock/Populate.pm'
);

notabs_ok($_) foreach @files;
done_testing;
