#!/bin/bash

#This document outlines how to set up a fully controlled environment for Perl.
#
#1. Install perlbrew
#

curl -sL https://install.perlbrew.pl | bash

#
#2. Add entry to ~/.bashrc
#

echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bashrc
source ~/perl5/perlbrew/etc/bashrc
which perl          # should be version managed by perlbrew

#
#3. Install a perl version known to support ASGS (takes 20-30 minutes)
#

perlbrew install perl-5.28.2

#
#Note: you may manage any number of versions of perl you wish, perlbrew builds and tracks them for you
#
#4. Set this perl to be your default perl, overriding the system perl on all interactive
#and batch terminal sessions
#

perlbrew switch perl-5.28.2

#
#Note: this operation can be reversed using
#
#  perlbrew switch-off
#
#You may want to make sure this is set correctly on login, so logout/back in again,
#

which perl          # should be version managed by perlbrew

#
#5. Install cpanm for easily managing the installed Perl modules from CPAN
#

perlbrew install-cpanm
which cpanm         # should be the one installed by perlbrew

#
#6. Install perl modules (see PERL-MODULES for current list), example (valid at time of this writing)
#

cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm Date::Format Date::Handler DateTime DateTime::Format::Builder IO::Socket::SSL HTTP::Tiny List::Util Math::Trig Net::FTP Params::Validate Time::Local

# interactive:

cpanm --force --interactive Date::Pcalc

#
#You should be all set up.
#
#Have fun!
