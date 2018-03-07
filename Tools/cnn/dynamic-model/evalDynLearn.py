#! /usr/bin/env python

import tensorflow as tf
import numpy as np
import os
import sys
import time
import datetime
import dataGiulioHelpers as data_helpers
from text_cnn import TextCNN
from tensorflow.contrib import learn
import csv

# Parameters
# ==================================================

# Data Parameters
tf.flags.DEFINE_string("positive_test", "./data/rt-polaritydata/rt-polarity.pos", "Data source for the positive data.")
tf.flags.DEFINE_string("negative_test", "./data/rt-polaritydata/rt-polarity.neg", "Data source for the negative data.")

# Eval Parameters
tf.flags.DEFINE_integer("batch_size", 64, "Batch Size (default: 64)")
tf.flags.DEFINE_string("checkpoint_dir", "", "Checkpoint directory from training run")
tf.flags.DEFINE_boolean("eval_train", False, "Evaluate on all training data")

# Misc Parameters
tf.flags.DEFINE_boolean("allow_soft_placement", True, "Allow device soft device placement")
tf.flags.DEFINE_boolean("log_device_placement", False, "Log placement of ops on devices")


FLAGS = tf.flags.FLAGS
FLAGS._parse_flags()
print("\nParameters:")
for attr, value in sorted(FLAGS.__flags.items()):
    print("{}={}".format(attr.upper(), value))
print("")


#
# Giulio changed to make simpler the code
#
datasets = None

# CHANGE THIS: Load data. Load your own data here
# Load data via the positive/negatives test data path (command parameter)
if FLAGS.positive_test and FLAGS.negative_test:
    datasets = data_helpers.robust_get_datasets_mrpolarity(FLAGS.positive_test,
                                                    FLAGS.negative_test)
    x_raw, y_test = data_helpers.robust_load_data_labels(datasets)
    y_test = np.argmax(y_test, axis=1)


    print("Total number of test examples: {}".format(len(y_test)))
else:
    print("Missing evaluation dataset")
    sys.exit()

#
# Giulio:
#
# # these are actially the 285 and 111 files of the oracle V5C14
#
#x_raw = ["public string NN is VBZ dependency NN resolution NN required VBN public string is dependency resolution required root ROOT required auxpass required is compound resolution dependency nsubjpass required resolution', 'the DT list NN of IN holes NNS If a DT point NN is VBZ in IN the DT hole NN it PRP is VBZ not RB in IN the DT polygon NN protected final list NN geo NN polygon NN holes NNS the list of holes If a point is in the hole it is not in the polygon protected final list geo polygon root ROOT polygon compound polygon geo holes"]
#x_raw = ["the DT list NN of IN holes NNS If a DT point NN is VBZ in IN the DT hole NN it PRP is VBZ not RB in IN the DT polygon NN protected final list NN geo NN polygon NN holes NNS the list of holes If a point is in the hole it is not in the polygon protected final list geo polygon root ROOT polygon compound polygon geo holes"]
#y_test = [1]

# Map data into vocabulary
vocab_path = os.path.join(FLAGS.checkpoint_dir, "..", "vocab")
vocab_processor = learn.preprocessing.VocabularyProcessor.restore(vocab_path)
x_test = np.array(list(vocab_processor.transform(x_raw)))

print("\nEvaluating...\n")

# Evaluation
# ==================================================
checkpoint_file = tf.train.latest_checkpoint(FLAGS.checkpoint_dir)
graph = tf.Graph()
with graph.as_default():
    session_conf = tf.ConfigProto(
        allow_soft_placement=FLAGS.allow_soft_placement,
        log_device_placement=FLAGS.log_device_placement)
    sess = tf.Session(config=session_conf)
    with sess.as_default():
        # Load the saved meta graph and restore variables
        saver = tf.train.import_meta_graph("{}.meta".format(checkpoint_file))
        saver.restore(sess, checkpoint_file)

        # Get the placeholders from the graph by name
        input_x = graph.get_operation_by_name("input_x").outputs[0]
        # input_y = graph.get_operation_by_name("input_y").outputs[0]
        dropout_keep_prob = graph.get_operation_by_name("dropout_keep_prob").outputs[0]

        # Tensors we want to evaluate
        predictions = graph.get_operation_by_name("output/predictions").outputs[0]
        scores = graph.get_operation_by_name("output/scores").outputs[0]

        # Generate batches for one epoch
        batches = data_helpers.batch_iter(list(x_test), FLAGS.batch_size, 1, shuffle=False)

        # Collect the predictions and scores here
        all_predictions = []
        all_scores = [] # giulio added a place to accumulate the scores
        for x_test_batch in batches:
            batch_predictions = sess.run(predictions, {input_x: x_test_batch, dropout_keep_prob: 1.0})
            score_predictions = sess.run(scores, {input_x: x_test_batch, dropout_keep_prob: 1.0})
            all_predictions = np.concatenate([all_predictions, batch_predictions])
            all_scores.append(score_predictions)


# output results modified by Giulio

for idx, s in enumerate (all_scores):
    print ("Score {}: {}".format(idx,s))

for idx, p in enumerate (all_predictions):
    print ("Prediction {}: {}".format(idx,p))

# Print accuracy if y_test is defined
if y_test is not None:
    correct_predictions = float(sum(all_predictions == y_test))
    accuracy = correct_predictions # we are doing leanve one out this we can simplify
    print("Total number of test examples: {}".format(len(y_test)))
    print("Accuracy: {:g}".format(accuracy))
else:
    print("Empty y_test make no sense")
    sys.exit()

if os.stat(FLAGS.positive_test).st_size != 0:
    if accuracy == 1:
        print("Test-{};{};{};{};{}".format(FLAGS.positive_test, 1, 0, 0, 0))
    else:
        print("Test-{};{};{};{};{}".format(FLAGS.positive_test, 0, 1, 0, 0))
else:
    if accuracy == 1:
        print("Test-{};{};{};{};{}".format(FLAGS.negative_test, 0, 0, 0, 1))
    else:
        print("Test-{};{};{};{};{}".format(FLAGS.negative_test, 0, 0, 1, 0))

# Save the evaluation to a csv
predictions_human_readable = np.column_stack((np.array(x_raw), all_predictions))
out_path = os.path.join(FLAGS.checkpoint_dir, "..", "prediction.csv")
print("Saving evaluation to {0}".format(out_path))
with open(out_path, 'w') as f:
    csv.writer(f).writerows(predictions_human_readable)
