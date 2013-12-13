
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Handy mock data creation",
  "AUTHOR" => "Gene Boggs <gene\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mock-Populate",
  "EXE_FILES" => [
    "bin/Date-Ranger",
    "bin/Number-Ranger",
    "bin/Passworder",
    "bin/Personify",
    "bin/Shuffler",
    "bin/Stats-Distrib",
    "bin/Time-Ranger"
  ],
  "LICENSE" => "perl",
  "NAME" => "Mock::Populate",
  "PREREQ_PM" => {
    "Data::SimplePassword" => 0,
    "Date::Range" => 0,
    "Date::Simple" => 0,
    "List::Util" => 0,
    "Mock::Person" => 0,
    "Statistics::Distributions" => 0,
    "Time::Local" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::SimplePassword" => 0,
  "Date::Range" => 0,
  "Date::Simple" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => 0,
  "Mock::Person" => 0,
  "Statistics::Distributions" => 0,
  "Test::More" => 0,
  "Time::Local" => 0,
  "lib" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



