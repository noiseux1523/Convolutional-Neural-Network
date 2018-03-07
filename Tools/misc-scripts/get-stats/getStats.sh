#!/bin/bash

#
# Just pass a folder name root of a hierarchy on which eval was done thus a checkpoints folder name
# this scripts extract from the .stats file lines relevant to compute
# accuracy measures
#
# sh getStats.sh runs/OracleV5C14-training/16-4-4/
#
# it creates 2 files tge summary and the rough-stats.csv
# this  later is used by processStats.pl to get final counts
# and accuracy
#


FolderName=$1

find ./$FolderName  -name ".stats" -exec cat {} \; > ./$FolderName/summary.txt


echo "TestFile; TP; FN; FP; TN" > ./$FolderName/rough-stats.csv

sed -n '/Test/p'   ./$FolderName/summary.txt   >> ./$FolderName/rough-stats.csv

exit
