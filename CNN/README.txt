./train.py --enable_word_embeddings false --positive_train="/Users/noiseux1523/cnn-text-classification-tf-w2v/data/rt-polaritydata/0-train-folded-argoUML.txt.pos" --negative_train="/Users/noiseux1523/cnn-text-classification-tf-w2v/data/rt-polaritydata/0-train-folded-argoUML.txt.neg"


./eval.py --eval_train --checkpoint_dir="./runs/1489631962/checkpoints/" --positive_test="data/rt-polaritydata/9-test-folded-argoUML.txt.pos" --negative_test="data/rt-polaritydata/9-test-folded-argoUML.txt.neg" > argoUML-fold9-stats.txt

====================================
TO TRAIN ON ALL FOLDS OF ALL SYSTEMS
====================================

1) go in main directory

2) copy and paste in ./data/5-Fold

3) modify train.txt file so it has this format :

	./data/5-Fold/ant/0-train-folded-ant.txt.neg:./data/5-Fold/ant/0-train-folded-ant.txt.pos
	./data/5-Fold/ant/1-train-folded-ant.txt.neg:./data/5-Fold/ant/1-train-folded-ant.txt.pos
	...
	...

4)

	cat ./data/train.txt | while read train; 
		do echo ${train}; 
		neg="$(echo ${train} | cut -d':' -f1)"; 
		pos="$(echo ${train} | cut -d':' -f2)"; 
		./train.py --enable_word_embeddings false --num_epochs 10 --positive_train=$pos --negative_train=$neg
	done

===================================
TO TEST ON ALL FOLDS OF ALL SYSTEMS
===================================

1) go in main directory

2) copy and paste in ./data/5-Fold

3) modify test.txt file so it has this format :

	./data/5-Fold/ant/0-test-folded-ant.txt.neg:./data/5-Fold/ant/0-test-folded-ant.txt.pos
	./data/5-Fold/ant/1-test-folded-ant.txt.neg:./data/5-Fold/ant/1-test-folded-ant.txt.pos
	...
	...

4) go in directory with all folds (e.g.: 5-Fold-80-train-20-test)

5) ls > directories.txt

	directories.txt: List of all models directory 

6) Use this format for directories.txt :

	./runs/1490112287/checkpoints/
	./runs/1490112309/checkpoints/
	...
	...

7)

	for fold in {1..45}; 
	do dir="$(sed "${fold}q;d" ./runs/directories.txt)";  
		test="$(sed "${fold}q;d" ./data/5-Fold/test.txt)";  
		neg="$(echo ${test} | cut -d':' -f1)";   
		pos="$(echo ${test} | cut -d':' -f2)";  
		echo $dir; 
		echo $test; 
		./eval.py --eval_train --checkpoint_dir=$dir --positive_test=$pos --negative_test=$neg > $dir.stats;  
	done

==============================
TO PUT ALL STATS IN CSV FORMAT
==============================

1) go in directory with model directories

2) find . -name ".stats" > stat.txt

3) cat ./stat.txt | while read stat;  do echo ${stat};  cat ${stat} >> stats.txt; done

4) perl ./generate-csv-files.pl --f stats.txt > stats.csv


















