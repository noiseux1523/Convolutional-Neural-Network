#!/usr/bin/perl

use Getopt::Long;

#
# EXAMPLE
#
# ./generate-csv-files.pl --f stats.txt > stats.csv
#
# --f stats.txt : List of all stats of all folds
#

# All options available
GetOptions( "verbose"  => \$verbose,	 
            "DBG=i"    => \$DBG,	  
            "f=s"      => \$f,	   
            "help+"    => \$help ); 

# Print help message
unless (!defined($help)) {
    print $helpMsg;
    exit(0);
}

# Open the input file and organize all data
print STDERR "Read file...\n";
print "Name;TP;FN;FP;TN;Positive_Precision;Positive_Recall;Positive_F1;Positive_Support;Negative_Precision;Negative_Recall;Negative_F1;Negative_Support;Precision;Recall;F1;Support\n";
$project = "NA";
$TP_tot = 0;
$FN_tot = 0;
$FP_tot = 0;
$TN_tot = 0;
$TP_all = 0;
$FN_all = 0;
$FP_all = 0;
$TN_all = 0;
my @files=();
open (FH, $f) or die" Unable to read file $f\n";
while (<FH>) {
  chop();
  if (/^NEGATIVE_TEST=.\/data\/(.*)\/(\d+)\-(.*)\-(.*).csv.neg$/) {
  	#print STDERR "$1 $2 $3\n";
    if (($2 == 0) and ($project ne "NA")) {
      $precision_tot = $TP_tot/($TP_tot+$FP_tot);
      $recall_tot = $TP_tot/($TP_tot+$FN_tot);
      $f1_tot = (2*$TP_tot)/((2*$TP_tot)+$FP_tot+$FN_tot);
      $res = "Total-$project;$TP_tot;$FN_tot;$FP_tot;$TN_tot;$precision_tot;$recall_tot;$f1_tot;;;;;;;;;\n";
      print "$res";
      $TP_tot = 0;
      $FN_tot = 0;
      $FP_tot = 0;
      $TN_tot = 0;
    } 
    $project = $3;
    $name = "$2-$3";
  } elsif (/^positive_examples(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)$/) {
  	#print "$2 $4 $6 $8\n";
  	$pos_precision = $2;
  	$pos_recall = $4;
  	$pos_f1 = $6;
  	$pos_support = $8;
  } elsif (/^negative_examples(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)$/) {
  	#print "$2 $4 $6 $8\n";
  	$neg_precision = $2;
  	$neg_recall = $4;
  	$neg_f1 = $6;
  	$neg_support = $8;
  } elsif (/^(\s+)avg \/ total(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)(\s+)([-+]?[0-9]*\.?[0-9]*)$/) {
  	#print "$3 $5 $7 $9\n";
  	$precision = $3;
  	$recall = $5;
  	$f1 = $7;
  	$support = $9;
  } elsif (/^\[\[(\s*)([0-9]*)(\s*)([0-9]*)\]$/) {
  	#print "$2 $4\n";
  	$TP = $2;
  	$FN = $4;
    $TP_tot = $TP_tot + $TP;
    $FN_tot = $FN_tot + $FN;
    $TP_all = $TP_all + $TP;
    $FN_all = $FN_all + $FN;
  } elsif (/^(\s)\[(\s*)([0-9]*)(\s*)([0-9]*)\]\]$/) {
  	#print "$3 $5\n";
  	$FP = $3;
  	$TN = $5;
    $FP_tot = $FP_tot + $FP;
    $TN_tot = $TN_tot + $TN;
    $FP_all = $FP_all + $FP;
    $TN_all = $TN_all + $TN;
  	$line = "$name;$TP;$FN;$FP;$TN;$pos_precision;$pos_recall;$pos_f1;$pos_support;$neg_precision;$neg_recall;$neg_f1;$neg_support;$precision;$recall;$f1;$support\n";
  	print "$line"
  }

  if (eof) {  # check for end of last file
    $precision_tot = $TP_tot/($TP_tot+$FP_tot);
    $recall_tot = $TP_tot/($TP_tot+$FN_tot);
    $f1_tot = (2*$TP_tot)/((2*$TP_tot)+$FP_tot+$FN_tot);
    $res = "Total-$project;$TP_tot;$FN_tot;$FP_tot;$TN_tot;$precision_tot;$recall_tot;$f1_tot;;;;;;;;;\n";
    print "$res";

    $precision_all = $TP_all/($TP_all+$FP_all);
    $recall_all = $TP_all/($TP_all+$FN_all);
    $f1_all = (2*$TP_all)/((2*$TP_all)+$FP_all+$FN_all);
    $res = "Total;$TP_all;$FN_all;$FP_all;$TN_all;$precision_all;$recall_all;$f1_all;;;;;;;;;\n";
    print "$res";
  }

}
close(FH);





























