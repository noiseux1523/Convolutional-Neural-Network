#!/usr/bin/perl

use Getopt::Long;
use List::Util qw(shuffle);
use Math::Round;

#
# EXAMPLE
#
# ./generate-pos-neg-files.pl --p ant-bodies-yes.csv --n ant-bodies-no.csv --foldnb 10
#
# --p ant-bodies-yes.csv : List of all SATD methods
# --n ant-bodies-no.csv : List of all non-SATD methods
# --foldnb 10 : Number of folds
#

my $foldnb=(); # Number of folds
my $p=(); # Filename of SATD methods
my $n=(); # Filename of no-SATD methods

# All options available
GetOptions( "verbose"  => \$verbose,	 
            "DBG=i"    => \$DBG,	  
            "p=s"      => \$p,	
            "n=s"      => \$n,	
            "foldnb=i"   => \$foldnb,
            "help+"    => \$help ); 

# Print help message
unless (!defined($help)) {
    print $helpMsg;
    exit(0);
}

# Open all the pattern files one by one and store it in negative or positive array of files
# print STDERR "Analyse positive and negative files...\n";
my @pos=();
my @neg=();

open (FH, $p) or die" Unable to read file $p\n";
while (<FH>) {
  chop();
  push @pos, "$_\n";
}
close(FH);

open (FH, $n) or die" Unable to read file $n\n";
while (<FH>) {
  chop();
  push @neg, "$_\n";
}
close(FH);

########################
# FOR foldnb FOLD VALIDATION
########################

# Create the 10 folds
# Create negative pattern folds
my @neg_fold;
$count = $#neg;
$foldcount = int($count / $foldnb + .5);
$foldnum = 0;
for ($i=0; $i<=$count; $i++) {
	if ($i >= ($foldnum+1)*$foldcount) {
		$foldnum++;
	}
	$j = rand($#neg+1);
	($line) = splice(@neg,$j, 1);
	$neg_fold[$foldnum] .= "$line";
}

# Create positive pattern folds
my @pos_fold;
$count = $#pos;
$foldcount = int($count / $foldnb + .5);
$foldnum = 0;
for ($i=0; $i<=$count; $i++) {
	if ($i >= ($foldnum+1)*$foldcount) {
		$foldnum++;
	}
	$j = rand($#pos+1);
	($line) = splice(@pos,$j, 1);
	$pos_fold[$foldnum] .= "$line";
}

# print STDERR "Print positive and negative files...\n";

# Print the 10 folds
for ($k = 0; $k < $foldnb; $k++) {
	# print STDERR "Writing negative file $k ...\n";
	# Print train negative patterns in a file
	my $filename_neg = "$k-train-$n.neg";
	unless(open FILE, '>'.$filename_neg) {
	    # Die with error message if we can't open it.
	    die "\nUnable to create $filename_neg\n";
	}
	# Write to file
	for($j=0; $j<$foldnb; $j++) {
		if ($j != $k) {
			print FILE $neg_fold[$j];
		} 
	}
	# Close train negative file
	close FILE;
	print "$filename_neg:";


	# Print test negative patterns in a file
	$filename_neg = "$k-test-$n.neg";
	unless(open FILE, '>'.$filename_neg) {
	    # Die with error message if we can't open it.
	    die "\nUnable to create $filename_neg\n";
	}
	# Write to file
	for($j=0; $j<$foldnb; $j++) {
		if ($j eq $k) {
			print FILE $neg_fold[$j];
		}
	}
	# Close test negative file
	close FILE;
	# print STDERR "$filename_neg done\n";


	# print STDERR "Writing positive file $k...\n";
	# Print train positive patterns in a file
	my $filename_pos = "$k-train-$p.pos";
	unless(open FILE, '>'.$filename_pos) {
	    # Die with error message if we can't open it.
	    die "\nUnable to create $filename_pos\n";
	}
	# Write to file
	for($j=0; $j<$foldnb; $j++) {
		if ($j != $k) {
			print FILE $pos_fold[$j];
		} 
	}
	# Close train positive file
	close FILE;
	print "$filename_pos\n";


	# Print test positive patterns in a file
	$filename_pos = "$k-test-$p.pos";
	unless(open FILE, '>'.$filename_pos) {
	    # Die with error message if we can't open it.
	    die "\nUnable to create $filename_pos\n";
	}
	# Write to file
	for($j=0; $j<$foldnb; $j++) {
		if ($j eq $k) {
			print FILE $pos_fold[$j];
		}
	}
	# Close test positive file
	close FILE;
	# print STDERR "$filename_pos done\n";
}




