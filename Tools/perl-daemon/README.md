
Preamble: Run faster a set of commands: ScreenQsubDaemon.pl
==============


To run hundreds or thousands of commands, possibly in parallel, the easiest way is to use
a  daemon ScreenQsubDaemon.pl  it is based on two perl packages:

** Proc-Daemon-0.23.tar.gz  **
** Proc-ProcessTable-0.53.tar.gz **


ScreenQsubDaemon.pl can work  with both screen and Torque.

Installing
--------------

Compile or recompile: 

Proc-Daemon-0.23.tar.gz  Proc-ProcessTable-0.53.tar.gz


this means open the tar; change directory and  execute:

perl Makefile.pl
make
make install

The commands above install under the system libraries; if you wish to keep  installation
under your home or you are not sysadmin just do:



perl Makefile.PL INSTALL_BASE=~/perl
make
make install


This install under your home the packages. Adjust the bash/shell environment to reflect
the installation:



export
PERLLIB=~/perl/lib/perl5/x86_64-linux-thread-multi/:~/perl/lib/perl5/:~/perl/lib/perl5/x86_64-linux-thread-multi/auto:




Running ScreenQsubDaemon.pl
--------------


ScreenQsubDaemon.pl  accept the flags:

-status
-stop
-status
-tasks


the flag tasks expect a file where each line is a comment to run, a shell scrip either for
screen or torque.  Each majo action is logges into a file log.txt. For example

ScreenQsubDaemon.pl  -status


check the status either ruinning or stop. ScreenQsubDaemon.pl  -stops the running
instance.


** Configuring **

You must first check and adjust the number of spanned children; this is hard coded:

use constant LIMIT => 12;

starts up to 12 processes in parallel;  adjust the polling intervals:

use constant SHORT_SLEEP => 2; # when firing up tasks in a screen wait  this amount of time 
use constant LONG_SLEEP => 60; # one all tasks are fired wait this number of seconds before checking if

Check the setup of your torque or screen tooling and verify it matches ScreenQsubDaemon.pl
.

You may also add an extra -runid parameter if needed to point to the top directory of cnn
models but you do not really need it if you keep the stricture of cnn software
 
















