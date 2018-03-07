#!/bin/bash

# ******************************************************************
# Super simplified script to train a set of  models; it uses a list of
# pairs of positive and negative train sets stored on a task/train file
# models are stored in a directory (second param).  It assumes
# models  are stored under runs/$1/#iteration-NBR
#
# Arguments: 
#	1) File with the list of pairs of training examples
#	2) Directory name to sture models 
#
# Example : 
#	bash run-all.sh data/train4C1one/train.txt train4C1one
#

# ******************************************************************


if [ $# -ne 2 ] ; then
    echo "illegal number of parameters"
    echo "expected:"
    echo "train-all.sh TaskName FolderName"
    exit 
fi


# Arguments

TaskName=$1	# Argument 1 -> Task name
FolderName=$2	# Argument 2 -> Folder name

# consistency  check 

if [ ! -f "$TaskName" ] ; then
    echo "missing task name (file not found)"
    echo "expected:"
    echo "train-all.sh TaskName FolderName"
    exit 
fi

if [ -d runs/$FolderName ] ; then
    echo "directory $FolderName already exists under runs please cleanup and remove it !"
    echo "expected:"
    echo "train-all.sh TaskName FolderName"
    exit 
fi


# Train on all folds of all systems
echo "Train on all folds..."
it=0 # added giulio

if [ !-d runs/$FolderName/ ] ; then
    mkdir -p runs/$FolderName
fi

cat $TaskName | while read train; 
	do echo "Training on ${train}..."; 
	neg="$(echo ${train} | cut -d':' -f1)"; 
	pos="$(echo ${train} | cut -d':' -f2)"; 

	# !!! FEEL FREE TO MODIFY PARAMETERS !!! #
	# Make sure to have enough epochs

	# No word custom embeddings
	# ./train.py --enable_word_embeddings false --num_epochs 6 --positive_train=$pos --negative_train=$neg

	./train.py --where runs/$FolderName/$it/ --enable_word_embeddings true --num_epochs 20 --dev_sample_percentage 0.1 --positive_train=$pos --negative_train=$neg --ymlconfig data/$FolderName/ConfigDict.yml # added giulio to stop after few iteration and check if needed ..
	
	it=$((it+1))  

	
	#if [ "$it" -eq "3" ] ;
	#then
	 #   exit
	#      echo " exit "
	#fi
	#sleep 5 # giulio: avoid overheating  
done

exit










