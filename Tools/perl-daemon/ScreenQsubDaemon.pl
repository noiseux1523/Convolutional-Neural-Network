#!/usr/bin/perl 

## you may need to adjust to reflect your installation

# I coded here both screen and qsub just be be more flexible there are 2 functions one for torque and one fos screen ...

use strict;
use warnings;
use Getopt::Long;
use Proc::Daemon;
use Cwd;
use File::Spec::Functions;
use File::Path qw(make_path remove_tree);


# change to 0 if you wish to use torque  instead of screen

use constant SCREEN => 1;


#
# the number of spanned processed depend on the memory be carefull and change here if needed
#

use constant LIMIT => 2;	# max number of spanned processes

#
# YOU MUST !!! hard code this in the clean function manchot has a weird buggy behaviour
# it is ignored in regexp!!!
#

# THI IS NOT ACTUALLY USED CHECK THE clean function and MODIFY IT IF NEEDED

use constant SNAME => 'LAPD';	# name of the id/process/task or screen prefix
# on recent Fedora servers there was a messy problem with global constant substitution in regexp
# thus I hard coded the name in the matching functions clean_qsub and clean_screen (see the end of this file)
#

use constant SHORT_SLEEP => 2; # when firing up tasks in a screen wait  this amount of time 
use constant LONG_SLEEP => 60; # one all tasks are fired wait this number of seconds before checking if
# another screen has to be fired up


my $build_command=();
my $get_running_kids= ();

# I know it =is ugly .. short in time ... 

if (SCREEN == 1){ 
  $build_command= \&build_command_screen;
  $get_running_kids= \&get_running_kids_screen;
}else{
  $build_command= \&build_command_qsub;
  $get_running_kids= \&get_running_kids_qsub;
}

my $pf = catfile(getcwd(), 'pidfile.pid');
my $daemon = Proc::Daemon->new(
			       pid_file => $pf,
			       work_dir => getcwd()
			      );
# are you running?  Returns 0 if not.
my $pid = $daemon->Status($pf);
my $daemonize = 1;

my $tasks=();			# file with list of spanning tasks
my @jobs =();			# actual list of jobs form file tasks

#
# if nothing else assume where data will be stored based on time
#
my $run_id=run_time();		# id for this run -default localtime
my $store_path="logs";		# default store path !
#
# this is a simplified daemon and thus the order of options is important
# when you start -tasks  MUST me the first parameter or the child will not see it
#
# starts as:
#
# ./ScreenQsubDaemon.pl  -tasks my_command_list.txt   -start
#

GetOptions(
	   'daemon!' => \$daemonize,
	   "tasks=s" => \$tasks,  # list of jobs one per line
	   "runid=s" => \$run_id, # prefix where data will be saved
	   "start" => \&run,
	   "status" => \&status,
	   "stop" => \&stop
	  );

sub stop {
  if ($pid) {
    print "Stopping pid $pid...\n";
    if ($daemon->Kill_Daemon($pf)) {
      print "Successfully stopped.\n";
    } else {
      print "Could not find $pid.  Was it running?\n";
    }
  } else {
    print "Not running, nothing to stop.\n";
  }
}

sub status {
  if ($pid) {
    print "Running with pid $pid.\n";
  } else {
    print "Not running.\n";
  }
}

sub run {
  if (!$pid) {
    print "Starting...\n";
    if ($daemonize) {
      # when Init happens, everything under it runs in the child process.
      # this is important when dealing with file handles, due to the fact
      # Proc::Daemon shuts down all open file handles when Init happens.
      # Keep this in mind when laying out your program, particularly if
      # you use filehandles.
      $daemon->Init;
    }

    # input tasks if any ...
    open(my $FH, '>>', catfile(getcwd(), "log.txt"));
    if (defined ($tasks)) {
      open (my $FT, $tasks);
      @jobs=<$FT>;
      close($FT);
      chop (@jobs);
    }

    print $FH "From >>$tasks<< Loaded Jobs: ", $#jobs+1,"\n";
    close($FH);
		

		
    while (1) {
      open(my $FH, '>>', catfile(getcwd(), "log.txt"));
      # any code you want your daemon to run here.
      # this example writes to a filehandle every 5 seconds.
      print $FH "Logging at " . time() . "\n\n";
      print $FH "Jobs: ", $#jobs+1,"\n\n";

      my @clines = &$get_running_kids($FH);
      
      my $processes = $#clines + 1;

      if ($processes < LIMIT) {
	  if ($#jobs>=0) {
	      print $FH "Jobs are: ", $#jobs+1, "\n";
	      print $FH "There are: ", $processes, " forked another process\n";
	      my $task = shift @jobs;
	  #
	  # no neeed to change signature just change the function body ...
	  #
	  my $cmd = &$build_command ($task,$run_id,$store_path, $FH);
	  my $name = $task;

	  system("$cmd");

	  print $FH "$cmd\n";
	  close $FH;
	      sleep SHORT_SLEEP;

	}else{
	  # here no jobs but possibly some running process ... sleep and wait ...
	  sleep LONG_SLEEP;
	}
      } else {
	print $FH "ZZZZZ .... Sleep " . LONG_SLEEP . " seconds ...\n";
	close $FH;
	sleep LONG_SLEEP;
      }
		  
    }
  } else {
    print "Already Running with pid $pid\n";
  }
}

#
# you will need to code your own function to build cammand line !
#

sub build_command_screen{
  my $task = shift;		# passed task
  my $run_id= shift;
  my $store_path = shift;
  my $FH=shift;


  #
  # task specific
  #

  # where to store stdout and stderr

  my $name = $task;
  $name =~ s/\.sh//g;
  $store_path=$store_path."/". $name . "-".run_time();
  my $dir = $store_path;
    #
  print $FH "RunId $run_id\n";
  print $FH "StorePath >>$store_path<<\n";
    #

    # do we need to create the rpository ?
	
    if ( ! -d $dir) {
      print $FH "\nCreateDir: >>$dir<\n";
      make_path ($dir );
    }

  # on recent centos 7 servers this simplified version does not work
  # a more complex for is needed; if you have problems try to change into:
  #
  # $cmd="screen -dmS LAPD  bash -c  \'sh $task\'"; 
  #
    my $cmd="screen -dmS giulio $task"; 


    return  $cmd;
	
  

}



sub build_command_qsub{
  my $task = shift;		# passed task
  my $run_id= shift;
  my $store_path = shift;
  my $FH=shift;


  #
  # task specific
  #

  # where to store stdout and stderr

  my $name = $task;
  $name =~ s/\.sh//g;
    $store_path=$store_path."/". $name . "-".run_time();
    my $dir = $store_path;
    #
    print $FH "RunId $run_id\n";
    print $FH "StorePath >>$store_path<<\n";
    #

    # do we need to create the rpository ?
	
    if ( ! -d $dir) {
      print $FH "\nCreateDir: >>$dir<\n";
      make_path ($dir );
    }

    my $cmd="qsub -e  $store_path -o $store_path  $task"; 


    return  $cmd;
	
  

}
sub get_running_kids_screen{
  my $FH=shift;
  open (my $PIPE, "screen -ls |") or print $FH "Unable to pipe\n;";
  my @lines = <$PIPE>;
  close ($PIPE);
  chop(@lines);
  my @clines = clean_screen ($FH,@lines);

}
sub clean_screen{
  my $FH=shift;
    my @lines = ();
    foreach (@_){

      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      #
      # there seems to be a big mess in  global variable sobstitution in regexp on Fedora thus I hard coded here the id to search
      #
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      
	push @lines, $_ if (/LAPD/);
    }
    return  (@lines)
}


sub get_running_kids_qsub{
  my $FH=shift;
  open (my $PIPE, "/usr/local/torque/bin/qstat -a |") or print $FH "Unable to pipe\n;";
  my @lines = <$PIPE>;
  close ($PIPE);
  chop(@lines);
  my @clines = clean_qsub ($FH,@lines);

}

sub clean_qsub{
  my $FH=shift;
    my @lines = ();
    foreach (@_){

      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      #
      # there seems to be a big mess in  global variable sobstitution in regexp on Fedora thus I hard coded here the id to search
      #
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      
	push @lines, $_ if (/LAPD/);
    }
    return  (@lines)
}


sub run_time{
my $tid=localtime();		# id for this run -default localtime

$tid =~ s/\s+/ /g;
$tid =~ s/ /-/g;
$tid =~ s/:/-/g;
return $tid;
}
