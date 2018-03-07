RUNNING CNN ON LAPD DATA
==============

The baseline code is a modified version of the git code:

https://github.com/dennybritz/cnn-text-classification-tf

here there are all the scripts needed to prepare data, create training scripts, create  scripts to run evaluation
and collect results.

Scripts are organized by function/activity. The workflos of one experiment is as follows:

** Create a CSV file where lines are instances of  LAPD (or not) **

** process the CSV  LAPD file to create training and test sets **

** Train  cnn-models  in  leave-one-out or cross-validation mode **

** Run cnn-models evaluations  on test data **

** Collect summary and rough statistics **

** Process rough stats to obtain final measures aka precision/recall/f1, ... **

There are at least two possible code examples  to start with CNN:


https://github.com/dennybritz/cnn-text-classification-tf

and the page:

https://mxnet.incubator.apache.org/tutorials/nlp/cnn.html

The code here is a variant of the git code. CNN as other deep learning beasts can model sentences either computing  embeddings at run time or
use pre-computed embeddings. Here embeddings are just a coding of words (including words contexts). If you are familiar with vector space models
embeddings are coefficients of a neural network that represent a word in its contexts much like  TF/IDF represent a word an a VSM model.

Differently from TF/IDF where each work is represented by a single real value and a sentence is just an array (bag of words), embeddings also model
the context of the sentence where the word was observed and are multidimensional real values arrays.

Actually, the simpler possible CNN  input is the one hot encoding. Suppose you have just 2 sentences:

like pizza
line panini

then you have a dictionary of 3 words: like, panini and pizza. Then I can represent each  word as a boolean  array. For example
pizza will be [0,0,1] and like [1,0,0] my first sentence thus will be a matrix with two rows( or columns)

1,0,0
0,0,1

the coding 1,0,0 (and the other two) are called one hot encoding. Of course you will do better (in general) if you will consider the
context and  use embeddings (aka the coefficients of a neural network trained on your sentences). Before that you must decide
how many real nubers will be user for each words, this is to say the dimensions of your emebddings. Typical values range
from 100 to 300; default often set at 128. Thus each single word will become an array of 128 numbers and a sentence a
matrix where each words will be 128 reals and thus will have 128 rows (or columns) and as many columns (or words) as there
are words in your sentence

Now embeddings can be pre-trained, there are sets like  Glove of embeddings trained on billion of words. Or you can train
your own using the word2vec program and a collect set of text fragments  (corpora) In such a case the CNN will receive as
input te pre-trained embedding and use then to represent you sentences. These are sometime referred as STATIC CNN
whereas if the first step of the CNN computes the embeddings these are often referred to as DYNAMIC models since they
adapt to your text.

The code here is the one used for  DYNAMIC models so you do not need word2vec to run an
experiment.

To start the computation under the directory corpora you have the leave one out sets for
oracle V5 column 14 and oracle V6.1 column one. Plus  the pre-trained dictionaries, if
you wish to experiment with static model.  Notice that the directory:

corpora/data/OracleV5C14-training

contains both training and test data and the training file list is

corpora/data/OracleV5C14-training/train.txt


First and foremost you have to install tensorflow and setup your environment.

Installing tensorflow 
--------------

There are several ways to install tensorflow but, perhaps, the easiest way  is via anaconda.  Under the directory Anaconda3 there are the two installer one for mac and one for linux
release  Nov 2017. Install anaconda under your home (default behaviour). Latest releases are available at:

https://www.anaconda.com/download/


Once installed, create a virtual environment:


conda create -n tensorflow python=3.6  # or python=2.7, etc.

Activate the conda environment by issuing the following command:

$ source activate tensorflow
(tensorflow)$  # Your prompt should change

install latest tensorflow version:

pip install --ignore-installed --upgrade TF_PYTHON_URL

chose the version from:

https://www.tensorflow.org/install/install_mac#the_url_of_the_tensorflow_python_package

again as of Nov 2017:

https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-1.4.0-py3-none-any.whl

thus

pip install --ignore-installed --upgrade  https://storage.googleapis.com/tensorflow/mac/cpu/tensorflow-1.4.0-py3-none-any.whl

Notice that to activate and deactivate the environment the commands are

source activate tensorflow

deactivate

these two commands just change your PATH environment variable, they are very slow,  thus to speed up scripts better avoid source activate tensorflow by
and hard code the PATH variable of the scripts.

Depending from the architecture you may or may not want to install scikit-learn and scipy in both  cases  once activated tensorflow
environment  (this time  via source activate tensorflow ) just install  with pip

pip install scikit-learn

pip install scipy


Create your experiment leave-one-out files
--------------

You need  a cvs file were each line is a LAPD instance and the second column is  zero (no instance) or one instance.
No matter  the other columns. Run the script split4one.pl;  for example

split4one.pl  instance-files.csv  lapd

it will create a directory  instance-file-training with the training, test and info files.  Numbers in file names are correspond to lines in the
instance file thus for example 43-train-lapd-no.neg means negative examples training  set created from line 43, this is to say the line 43 was left out
and then used to create the test set.


Run cnn training 
--------------

** Preprocessing **

First step is to generate a bunch of shell scripts one for each datum (or for each fold). The script genDynBatch.pl does exactly that.
It takes a list of training configurations and a string used to create a directory where shell script are stored.  Each line in the training
file created by split4one.pl  is something like

 negative-set-training-file:positive-set-training-file

You MUST  adapt the script to your ENVIRONMENT. There are few things to consider. To run training you need to activate tensorflow this is
very slow but in essence it just changes the environment PATH variable thus it pays just to set the right PATH before running the training command.

Unfortunately  such a path depend on the machine you run the scripts thus you must adapt to your running environment !

Last but not least, you must modify the hard coded network parameters, the default values there are

# number of filters
my $nfilt = 16;
# shape of filters aka size of each filter
my $fsizes = "4,4,4,4";
# embedding dimension
my $edim = 150;


suppose you need a 64 filters with shapes 3,4,5,7 and embeddings of 256 you will thus edit

# number of filters
my $nfilt = 64;
# shape of filters aka size of each filter
my $fsizes = "3,4,5,7";
# embedding dimension
my $edim = 256;


**  Hacking the tensorflow session**

A tensorflow computation is described by a graph; each computation runs into a session and you may/must  adjust
session parameters. There are two hidden params that can give  you a lot of trouble they are:

*intra_op_parallelism_threads*
*inter_op_parallelism_threads*

they define how agressive tensorflow will be in creating multiple threads.  Keep in mind tensorflow has been designed to match
Google needs and   needs to be adapted to suite your needs. Now you  go back to your hardware configuration. 
You must account for the computational power you have this is to say CPU, cores,  threads or GPUs.

Suppose you have a Mac pro (2.8 GHz Intel Core i7) this likely will have a quad core cpu
where each core can run 2 threads thus the max number of  parallel threads will be 8.

But perhaps you wish to keep one core (two threads) free while doing a training. If you run a single training script a reasonable
configuration  will be use at most 6 threads:

session_conf = tf.ConfigProto(
        intra_op_parallelism_threads=6,# note this must me manually tuned on the hardware available
                                        # supposed you have a 4core and each core has 2 threads
                                        # then the max thread number is 4x2 BUT perhaps you better keep
                                        # one core free for other processes thus may be safe
                                        # stay in 4 or 6 threads in intra_op_parallelism_threads
        inter_op_parallelism_threads=0, # this should really be zero .. no point for now other values 
        allow_soft_placement=FLAGS.allow_soft_placement,
        log_device_placement=FLAGS.log_device_placement)

However of you wish to run 3 training in parallel then each training should be


session_conf = tf.ConfigProto(
        intra_op_parallelism_threads=2,# note this must me manually tuned on the hardware available
                                        # supposed you have a 4core and each core has 2 threads
                                        # then the max thread number is 4x2 BUT perhaps you better keep
                                        # one core free for other processes thus may be safe
                                        # stay in 4 or 6 threads in intra_op_parallelism_threads
        inter_op_parallelism_threads=0, # this should really be zero .. no point for now other values 
        allow_soft_placement=FLAGS.allow_soft_placement,
        log_device_placement=FLAGS.log_device_placement)

this to avoid contention between training processes and ultimately making things slower.

**  Manually running a training **

Sometime it may be useful to check if generated scripts work or just run a  train by hand.
Suppose you use trainDyn.py then fisrt activate tensorflow then  the command is:

./trainDyn.py --where store_dir -embedding_dim  150 --num_filters 16  --filter_sizes "5,5,5,5"  \
--num_epochs 100 --dev_sample_percentage 0.1  --positive_data_file=data/OracleV5C14-training/96-train-lapd-yes.pos \
--negative_data_file=data/OracleV5C14-training/96-train-lapd-no.neg


of course you need to adjust the where directory, the positive and negative training files, and perhaps change
embedding size (150 here) or the number of filters (16 here) and filter types (5,5,5,5 here this is to say  5 filters of step 5).


**  Let's be eager  use a daemon**

There is no point in wasting time lunching a bunch of shell scripts by hand; much better let a daemon do it for you.
this is the role of ScreenQsubDaemon.pl the perl daemon that takes a list of tasks and,  depending on the config,
ir runs multiple task in parallel via screen or torque. It is a polling daemon that every few seconds checks  if a new task
must be started. Timing is programmed via two constants

SHORT_SLEEP => 2
LONG_SLEEP => 60

when firing up processes it waits 2 seconds every time a new process is started. Then, if the max number of processes is reached it waits
60 seconds between two checks. Of course you need to adjust the  frequencies to match your  goal.

Last change  manually in ScreenQsubDaemon.pl the number of parallel process you wish to run
default 2:

LIMIT => 2

keep in mind each task (training task) may need multiple threads  thus on a Mac pro you probably do not want more than 2 or 3 parallel tasks.

Kee in mind 99% probability to run the daeom you will need to install two perl components Proc-ProcessTable and Proc-Daemon;
see the readme in the directory perl-daemon.

Run model evaluations  on test data
--------------

Once model are trained we  are ready to go to run the network on  test data. Here the task
is  to collect  the  list of  checkpoints  directories  and then  run  on each  checkpoint
directory the evaluation  for the given test  data. Remember that train and  test data are
specific to the model.  An evaluation is just like a training step just much less resource demanding and
much faster.  Suppose you use evalDynLearn.py then  an evaluation  will be:

./evalDynLearn.py  --checkpoint_dir=chk_dir --positive_test=my_pos_test  --negative_test=my_neg_test

it si important  to chose the "right" test  data. To simplify the task  remember that each
line i the csv file generated a leave-one-out set and that training and test set have file
names beginning with the line number of the csv file. This if we  consider line 92, there will be
training and test set files with 92 as beginning for this is to say:

data/OracleV5C14-training/92-test-lapd-no.neg
data/OracleV5C14-training/92-test-lapd-yes.pos

you wil have trained the model on

data/OracleV5C14-training/92-train-lapd-no.neg
data/OracleV5C14-training/92-train-lapd-yes.pos

this means the eval will be something like:

./evalDynLearn.py  --checkpoint_dir=./runs/OracleV5C14-training/16-5/92/1511657066/checkpoints \
--positive_test=data/OracleV5C14-training/92-test-lapd-yes.pos \
--negative_test=data/OracleV5C14-training/92-test-lapd-no.neg

the program wil output  results on the stdout thus redirect to a file!

Of course doing by hand is not feasible. Just use the script genDynEval.pl it take a file with the list of
checkpoints. It assume the par=th start with ./   and this is very important. File names are computed
assuming / as separator and give the position of fileds. For example a line looks like

./runs/OracleV5C14-training/16-3/262/1511208681/checkpoints

notice the fourth fiel the model id and the fifth the train time stamp. The script needs the
forth field  be the id and the 3d the config (16-3 in this example). In this way we know
what training and test files are and what training experience we run.

The second parameter is just a string used to compose the directory name where script will be stored.
Suppose we call the program as:

./genDynEvalBatch.pl  checkpoints.list OracleV5C14


the you will find a bunch of script files stored into OracleV5C14-eval-batch.

Again, you do not need to run generated scripts by hand, just create a list of scripts, adjust 
ScreenQsubDaemon.pl  number of parallel  processes (here you can exaggerate, say one process
per thread or more) and run the evaluations.

Scripts redirect the evaluation stdout into the checkpoints directory in a file names .stats


Collect summary and rough statistics
--------------

Once model have been evaluated we have a bunch of .stats file one per checkpoints directory.
To collect and aggregate data run the script getStats.sh, it takes a path, scans the path for .stats file
and extract line formes as Test-#;#;#;#  For example, if you call the script

sh getStats.sh runs/OracleV5C14-training/16-4-4/


assuming runs/OracleV5C14-training/16-4-4/ is  where checkpoints  for the model 16-4-4
aka 16 filters shapes 4,4  this is to say two families of filtes with step 4 and each with 16 members.
The scripts create two files, here under runs/OracleV5C14-training/16-4-4, a summary.txt containing  all
information and one rough-stats.csv where the format is:

TestFile; TP; FN; FP; TN

(TP true positives ....).


Process rough stats to obtain final measures
--------------

Rough true positive, true negative etc stats need to me aggregated to get precision, recall. f1, etc.
Just run the script  processStats.pl it takes  rough stat file and a label; for example:

./processStats.pl   runs/OracleV5C14-training/32-1/rough-stats.csv  32-1

will process  the results of the experiment 32-1 and create a line with:
Configuration,Recall,Precision,Specificity,F1,Accuracy.

here configuration (the second parameter passed) will be 32-1.
