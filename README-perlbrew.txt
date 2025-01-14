Table of Contents:

I.  Installing perlbrew and your desired version(s) of perl
II.  Setting up the perl environment of your dreams
III. perlbrew environment, ASGS, and HPC batch jobs
IV.  Autmating this process

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This document outlines how to set up a fully controlled environment for perl.

I. Installing perlbrew and your desired version(s) of perl

0. Login to the head node of the computing system where you'll be installing perlbrew

1. Install perlbrew

  curl -L https://install.perlbrew.pl | bash

2. Add entry to one or all of the following 

  echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.profile      # legacy supported by bash, but used by the original Bourne shell (/bin/sh)
  echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bash_profile # offical bash file, read ONCE on interactive login (e.g., when you first ssh to the host)
  echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bashrc       # read whenever a shell is started, including when ssh is used non-interactively

It is recommended that you place it in ~/.bash_profile when running ASGS, assuming you will be
starting it up from an interactive session. The batch queue system should inherit the interactive
environment when ASGS submits jobs to the queue. If you plan on issuing commands over ssh to the
host machine non-interactively (e.g., ssh user@host "command to execute"), then place the source'ing
of the perlbrew resource file into ~/.bashrc. There should be no reason to place it in ~/.profile
since this is a hold over from the old Bourne shell.

NOTE: You may wish to add this line to ~/.profile instead

Once this is done, logout and back in again; make sure perlbrew is in your PATH:

   which perlbrew

If not, make sure you've placed the source line in the correct file.

3. Install a perl version known to support ASGS (takes 20-30 minutes)

Note: it would be convenient to open a screen sessin if you wish to see it compiling and installing
since perlbrew will give you the tail command to use to do this. If not then perlbrew just waits for
the background process to complete with no feedback indicating that anything is happening. You may
install as many versions of perl as you whish using this method. perl 5.28.2 is the latest version
of perl at the time of this writing.

  perlbrew install perl-5.28.2

4. Set this perl to be your default perl, overriding the system perl on all interactive and batch
terminal sessions; when ~/perl5/perlbrew/etc/bashrc is source'd on login or new shell, it will automatically
set your environment to point to the version of perl you have specificed. Fixing it so that the
perlbrew installed version of perl is set by default is recommended:
   
  perlbrew switch perl-5.28.2

If you wish to default to system perl on login, but switch to a version of perl after manually, then
use the following command after login:

  perlbrew use perl-5.28.2

You may undo the "perlbrew switch" using the following command:

  perlbrew switch-off

II. Setting up the perl environment of your dreams

Make sure the perl you're expecting is first in the PATH:

  which perl          # should be version managed by perlbrew

1. Install cpanm for easily managing the installed perl modules from CPAN using the following commands:

  perlbrew install-cpanm
  which cpanm         # should be the one installed by perlbrew

2. Install perl modules (see PERL-MODULES for current list), example (valid at time of this writing)

  # first, install local::lib
  cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

  # install everything else
  cpanm Date::Format Date::Handler DateTime DateTime::Format::Builder IO::Socket::SSL HTTP::Tiny List::Util Math::Trig Net::FTP Params::Validate Time::Local 

  # currently, Date::Pcalc requires some interaction
  cpanm --force --interactive Date::Pcalc

  Choose "p" for the pure Perl version.

  Note: --interactive is used because it asks if you want the compiled version ([c], default) or the pure Perl version ([p]).
  --force is used because there is a test in the Date::Pcalc test suite that is failing, but it won't effect ASGS.

3. Setting up a Perl development environment

  We wish to use perltidy to enforce standard "best" formatting, so install it with the following command:

  cpanm Perl::Tidy
  which perltidy      # should point to the version of perltidy installed by cpanm
  cp PERL/perltidyrc ~/.perltidyrc # ASGS standard perltidy options

  The use of perltidy is outside the scope of this README, but a quick start for anyone using vim is as follows.
  When wishing to tidy a Perl file inside of the vim editor, issue the following keystrokes:

  <esc>:!perltidy
  
  This command will tidy everything in the currently visible file. 

  One last note about tidying a file that has not been tidied ever, if you're making other changes be sure to save the tidy
  as a separate commit either before or after you commit the functional changes you're making in the Perl file. Thiis is
  so that anyone looking at the commit or reviewing the pull request can see the actual functional changes instead of being
  hidden among benign formatting changes.

You should be all set up.

III. perlbrew environment, ASGS, and HPC batch jobs

1. To be safe, test to make sure the environment in your interactive login session (or whatever kind of session in which
you're initiating ASGS or submitting jobs to the queue) is inherited in the compute node session. For example, lonestar5
at TACC has the "idev" tool that will launch an interactive session on a compute node. Do that then just issue the
"which perl" commend. It should point to the version installed by perlbrew. To be extra safe, add as debugging output
in any queue script, "which perl" - the job output should reflect the proper perl is picked from the PATH.

2. In order for ASGS' Perl scripts to run properly on both the interactive login node and on the compute nodes, be sure
to follow the following guide:

a. the shebang (first line) in any .pl script should be:
  
  #!/usr/bin/env perl

b. make sure the .pl script is chmod'd to be executable:

  chmod 750 /path/to/script.pl

c. Perl modules should contain NO shebang line at all, they are meaningless*

~~~~~
* There is a caveat to this, and it's when writing something called a modulino that is both a script and a proper Perl 
library, but we do not have any of those (yet); when the time comes this document will be updated to reflect this case
as well.

IV.  Autmating this process

1. There is value in stepping through this document manually, but there is a basic script that attempts to autmate the setup
in the ASGS repository under the file, "cloud/general/init-perlbrew.sh".
     
Have fun!
