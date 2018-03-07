#!/bin/bash

# ******************************************************************
# All in one script that create folds, train models and test models
#
# Arguments: 
#	1) File with the list of systems to process (based on the name of the folder with the comment patterns in encoded-comment-files)
#	2) Number of folds desired
#
# Example : 
#	bash run-all.sh systems.txt 10
#
# Folders :
#	encoded-comment-files -> Contains all the system folders, which contains the comment patterns
#	data -> Data folder containing data for each runs in automatically generated unique folders (unique ID + number of folds)
#
#			A fold is divided in 4 files, here is an example for 10-fold cross validation :
#			 	{Fold#}-test-folded-{System}.txt.neg  : Test set for non-SATD patterns (10% of all non-SATD patterns)
# 				{Fold#}-test-folded-{System}.txt.pos  : Test set for SATD patterns (10% of all SATD patterns)
# 				{Fold#}-train-folded-{System}.txt.neg : Train set for non-SATD patterns (90% of all non-SATD patterns)
# 				{Fold#}-train-folded-{System}.txt.pos : Train set for SATD patterns (90% of all SATD patterns)
#			So, for 9 systems and a 10-fold cross validation we will have :
#				(9 systems) * (10 folds) * (4 files) = 360 files combined for training and testing
#
# 	runs -> Folder containing the trained models in automatically generated unique folders (unique ID)
#			
#
# ******************************************************************

# Arguments
Folds=$1   # Argument 1 -> Number of folds
FolderName=$2	# Argument 2 -> Folder name
RunsName=$3	# Argument 3 -> Folder which contains models
TrainName=$4	# Argument 4 -> Training file
TestName=$5	# Argument 5 -> Test file
ConfigFile=$6	# Argument 6 -> Config file

# Train on all folds of all systems
echo "Train on all folds..."
cat ./data/$FolderName/$TrainName | while read train; 
	do echo "Training on ${train}..."; 
	neg="$(echo ${train} | cut -d':' -f1)"; 
	pos="$(echo ${train} | cut -d':' -f2)"; 

	# !!! FEEL FREE TO MODIFY PARAMETERS !!! #
	# Make sure to have enough epochs

	# No word custom embeddings
	# ./train.py --enable_word_embeddings false --num_epochs 6 --positive_train=$pos --negative_train=$neg

	./train-all-comments.py --enable_word_embeddings true --num_epochs 6 --dev_sample_percentage 0.01 --num_filters 128 --batch_size 32 --where $RunsName --config $ConfigFile --positive_train=$pos --negative_train=$neg

done

# Test on all folds of all systems
echo "Test on all folds..."
mkdir ./$RunsName/$FolderName
it=1
find ./$RunsName -maxdepth 2 -name "checkpoints" | while read dir;
	do test="$(sed "${it}q;d" ./data/$FolderName/$TestName)";  
	neg="$(echo ${test} | cut -d':' -f1)";   
	pos="$(echo ${test} | cut -d':' -f2)";  
	echo $dir; 
	echo $test; 

	./eval.py --eval_train --batch_size 32 --checkpoint_dir=$dir --positive_test=$pos --negative_test=$neg > $dir/.stats;  

	folder="${dir/\/checkpoints/ }"
	mv $folder ./$RunsName/$FolderName
	it=$((it+1))
done

# Write results in .csv file
echo "Writing results of $FolderName..."

# Verification
if [ -f ./$RunsName/$FolderName/stats.txt ] ; then
  rm ./$RunsName/$FolderName/stats.txt
fi

echo "Saving text stats..."
find ./$RunsName/$FolderName -name ".stats" | while read stat  
  do cat ${stat} >> ./$RunsName/$FolderName/stats.txt 
done

echo "Combining all stats in csv format..."
perl ./generate-csv-files.pl --f ./$RunsName/$FolderName/stats.txt > ./$RunsName/$FolderName/stats.csv











