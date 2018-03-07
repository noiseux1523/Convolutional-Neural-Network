#!/opt/local/bin/perl

use List::Util qw(shuffle);


my @array = <>;

my @sorted = shuffle @array;
print @sorted;
exit(0);

