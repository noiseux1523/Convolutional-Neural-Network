#!/bin/bash

# ******************************************************************
# Super simplified script to eval a set of models given a list of test set pairs.
# It assumes a naming convention; file names must start with a number and that number
# allow  to identify the model to check 
# Arguments: 
#	1) File with the list of  test tases to run
#	1) Folder name under runs
#
# Example : 
#	bash eval-all.sh  task-list.txt
#
#
# ******************************************************************

# Arguments
TestName=$1   # Argument 1 -> Number of folds
FolderName=$2	# Argument 2 -> Folder name

# Train on all folds of all systems
#
# Test on all folds of all systems
#
echo "Test on all folds..."

it=1
#find ./runs -maxdepth 2 -name "checkpoints" | while read dir;
find ./runs/$FolderName  -maxdepth 6 -name "checkpoints" |sort -t'/' -k5 -n | while read dir; # making sure we have the right order
	do test="$(sed "${it}q;d" $TestName)";  
	neg="$(echo ${test} | cut -d':' -f1)";   
	pos="$(echo ${test} | cut -d':' -f2)";  
	echo $dir; 
	echo $test; 

	./eval_LOO.py --eval_train --checkpoint_dir=$dir --positive_test=$pos --negative_test=$neg --ymlconfig configC14.yml > $dir/.stats;  

	
	it=$((it+1))

done


find ./runs/$FolderName  -name ".stats" -exec cat {} \; > ./runs/$FolderName/summary.txt


echo "TestFile, TP, FN, FP, TN" > ./runs/$FolderName/rough-stats.csv

sed -n '/Test/p'   ./runs/$FolderName/summary.txt   >> ./runs/$FolderName/rough-stats.csv

exit

# not sure we really need this ...

echo "Combining all stats in csv format..."
perl ./generate-csv-files.pl --f ./runs/$FolderName/stats.txt > ./runs/$FolderName/stats.csv











