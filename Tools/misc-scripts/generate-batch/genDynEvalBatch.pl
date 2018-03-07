#!/opt/local/bin/perl

use strict;

# the first param is a train/task file then each line is used to create a job to run on manchot
# to simplify things it assume a second param is given with the name of the specifi task aka OracleV5C13-training
#
# ./genDynEvalBatch.pl  checkpoints.list OracleV5C14
#

#
# there are ugly hardcoded  parameters. The list MUST start with ./
# the name of directory containing test data MUST be done in a certain way
# basically the second parameter MUST be concatenated with data/... to get the place etc etc
#

# The name of the evaluation script IS HARD CODED

#
# THE PATH VARIABLE IS HARD CODED TOOO!!!!!
#

my $GPATH="/usagers/p302225/anaconda3/envs/tensorflow/bin:/usagers/p302225/anaconda3/bin:/usagers/p302225/anaconda3/bin:/usr/local/torque/bin:/usr/local/torque/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/lib64/openmpi/bin:/usagers/p302225/.local/bin:/usagers/p302225/bin\n";

my $CONDA_PATH=":/usagers/p302225/anaconda3/bin:/usagers/p302225/anaconda3/bin:/usr/local/torque/bin:/usr/local/torque/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/lib64/openmpi/bin:/usagers/p302225/.local/bin:/usagers/p302225/bin\n";

my $CONDA_PREFIX="/usagers/p302225/anaconda3/envs/tensorflow\n";

my $py_exec="evalDynLearn.py";

## code starts here

open (FH, $ARGV[0] ) or die" Unable to read file $ARGV[0] \n";
my @lines = <FH>;
close(FH);
chop(@lines);

# create a batch dir if not there

my $bplace = $ARGV[1] . "-eval-batch";
my $dplace = "data/".$ARGV[1]."-training";

mkdir $bplace if ( ! -d $bplace);

my $cntr=1;
foreach my $l (@lines){
  print "$l\n";
  my @fields=split("/",$l);
  my $config=$fields[3];
  my $id=$fields[4];
  
  my ($n,$p)=();
  $n=$id."-test-lapd-no.neg";
  $p=$id."-test-lapd-yes.pos";

my $code =$id;

print "\t$code: task $cntr\t$n --> $p\n";

my $job_name=$ARGV[1] . "-job-".$config."-".$code.".sh";
my $jfile = $bplace ."/".$job_name;

open (FM,">$jfile") or die "Unable to create info file $jfile";
print FM "#!/bin/bash\n\n";


print FM "#PBS -N eval_$code\n";
print FM "#PBS -q recherche\n";
print FM "#PBS -M giuliano.antoniol\@polymtl.ca\n\n";


print FM "PATH=$GPATH\n\n";
print FM "CONDA_PATH_BACKUP=$CONDA_PATH\n\n";
print FM "CONDA_PREFIX=$CONDA_PREFIX\n\n\n";

print FM "cd ~/LAPD/\n\n";

print FM "neg=\"data/$ARGV[1]-training/$n\"\n";
print FM "pos=\"data/$ARGV[1]-training/$p\"\n";

my $cmd="./$py_exec  --checkpoint_dir=$l";
$cmd .= " --positive_test=\$pos";
$cmd .= " --negative_test=\$neg";

print FM "$cmd > $l/.stats\n";

 print FM "exit\n";
close(FM);

$cntr++;


}


exit(0);
