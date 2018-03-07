#!/opt/local/bin/perl

use strict;

#
# the script generate a bunch of shell script each one training one instance of CNN. It takes
# a list of training set pairs, one pait per line, in the format
# negative-set-training-file:positive-set-training-file
#
# since the training code was inspired by https://github.com/dennybritz/cnn-text-classification-tf
# much likely you will have tha training files under data and thus lines should be something like:
#
# data/OracleV5C14-training/42-train-lapd-no.neg:data/OracleV5C14-training/42-train-lapd-yes.pos
#
# The second parameter is a prefix used to create a directory (appending the string -batch) where
# scripts are saved.


# The name of the evaluation script IS HARD CODED as well as the environment variable

#
# THE PATH VARIABLE IS HARD CODED TOOO!!!!!
#

my $GPATH="/usagers/p302225/anaconda3/envs/tensorflow/bin:/usagers/p302225/anaconda3/bin:/usagers/p302225/anaconda3/bin:/usr/local/torque/bin:/usr/local/torque/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/lib64/openmpi/bin:/usagers/p302225/.local/bin:/usagers/p302225/bin\n";

my $CONDA_PATH=":/usagers/p302225/anaconda3/bin:/usagers/p302225/anaconda3/bin:/usr/local/torque/bin:/usr/local/torque/sbin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/lib64/openmpi/bin:/usagers/p302225/.local/bin:/usagers/p302225/bin\n";

my $CONDA_PREFIX="/usagers/p302225/anaconda3/envs/tensorflow\n";

my $py_exec="trainDyn.py";


### hard coded params MODIFY BY HAND !

# number of filters
my $nfilt = 16;
# shape of filters aka size of each filter
my $fsizes = "4,4,4,4";
# embedding dimension
my $edim = 150;
#
# run
#
# ./genDynBatch.pl   data/OracleV6.1C1-training/train.txt OracleV6.1C1-training
#


# the first param is a train/task file then each line is used to create a job to run on manchot
# to simplify things it assume a second param is given with the name of the specifi task aka OracleV5C13-training

#
# !!!!!!!!!!!!!!!!!!!!!! BE AWARE !!!!!!!!!!!!!!!!!!!!
# You may need to modify the print

open (FH, $ARGV[0] ) or die" Unable to read file $ARGV[0] \n";
my @lines = <FH>;
close(FH);
chop(@lines);

# create a batch dir if not there

my $bplace = $ARGV[1] . "-batch";

mkdir $bplace if ( ! -d $bplace);

my $cntr=1;
foreach my $l (@lines){
print "$l\n";
my ($n,$p)=split(":",$l);

my $code =();
if ( $n =~ /(\d+)\-train\-.*/){
  $code = $1;
}else{
  die "Wrong line format at $l missin line number\n"
}

print "\t$code: task $cntr\t$n --> $p\n";

my $config=$nfilt ."-". $fsizes;
$config =~ s/,/\-/g;
my $job_name=$ARGV[1] . "-".$config."-dyn-job-".$code.".sh";
my $jfile = $bplace ."/".$job_name;

open (FM,">$jfile") or die "Unable to create info file $jfile";
print FM "#!/bin/bash\n\n";


print FM "#PBS -N train_$code\n";
print FM "#PBS -q recherche\n";
print FM "#PBS -M giuliano.antoniol\@polymtl.ca\n\n";

print FM "cd ~/LAPD/\n\n";

#print FM "source activate tensorflow\n\n";



print FM "neg=\"$n\"\n";
print FM "pos=\"$p\"\n";
print FM "where=\"runs/$ARGV[1]/$config/$code/\"\n";



print FM "PATH=$GPATH\n\n";
print FM "CONDA_PATH_BACKUP=$CONDA_PATH\n\n";
print FM "CONDA_PREFIX=$CONDA_PREFIX\n\n\n";



my $cmd="./$py_exec --where \$where  --embedding_dim  $edim --num_filters $nfilt  --filter_sizes \"$fsizes\"  --num_epochs 100 --dev_sample_percentage 0.1 ";
$cmd .= " --positive_data_file=\$pos";
$cmd .= " --negative_data_file=\$neg";

print FM "$cmd\n";
print FM "exit\n";
close(FM);

$cntr++;


}


exit(0);
