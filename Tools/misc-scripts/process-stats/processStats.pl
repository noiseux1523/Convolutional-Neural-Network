#!/opt/local/bin/perl

# first param is the name of a  cvs  file  separated with ; with first line header and
# next lines contain:
#
# TestFileId; TP; FN; FP; TN
#
# second param is a label, a  label to name  the row
#
# example
#
# ./processStats.pl   runs/OracleV5C14-training/32-1/rough-stats.csv  32-1


use strict;

my $label = $ARGV[1];

open (FH, $ARGV[0] ) or die" Unable to read file $ARGV[0] \n";
my @lines = <FH>;
close(FH);
chop(@lines);
my $TP=0;
my $FP=0;
my $TN=0;
my $FN=0;

my $sum_TP=0;
my $sum_FP=0;
my $sum_TN=0;
my $sum_FN=0;
my $tc=();
shift @lines;

foreach (@lines){
  ($tc,$TP, $FN, $FP, $TN)=split(';');
  $sum_TP+= $TP;
  $sum_FP+= $FP;
  $sum_TN+= $TN;
  $sum_FN+= $FN;
  
}

my $N=$sum_TP+$sum_FP+ $sum_TN+$sum_FN;

my $precision = 100*$sum_TP/($sum_TP+$sum_FP);
my $recall= 100*$sum_TP/($sum_TP+$sum_FN);
my $f1= 100*2*$sum_TP/(2*$sum_TP+$sum_FP+$sum_FN);
my $accuracy= 100*($sum_TP+$sum_TN)/$N;
my $specificity=100* $sum_TN/$N;
print "Configuration,Recall,Precision,Specificity,F1,Accuracy\n";
printf("%s,%.2f,%.2f,%.2f,%.2f,%.2f\n", $label,$recall,$precision,$specificity,$f1,$accuracy);
exit(0)
