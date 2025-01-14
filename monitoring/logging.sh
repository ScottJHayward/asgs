#!/bin/bash
#----------------------------------------------------------------
#
# logging.sh: This file contains functions required for logging.
# It is sourced by asgs_main.sh and any other shell script that 
# requires logging capabilities. 
#
#----------------------------------------------------------------
# Copyright(C) 2012--2019 Jason Fleming
#
# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ASGS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------
#
# Log file will be in the directory where the asgs was executed
#
#  send message when shutting down on INT and clear all processes
sigint() {
   RMQMessage "EXIT" "EXIT" "asgs_main.sh>sigint()" "EXIT" "Received Ctrl-C from console.  Shutting ASGS down ..." 
   allMessage "Received Ctrl-C from console.  Shutting ASGS instance $INSTANCENAME down."
   trap - SIGTERM && kill -- -$$ # "untrap" SIGTERM and send SIGTERM to all processes in this process group 
   exit 0
}
#
#  send message when shutting down on TERM and clear all processes 
sigterm() {
   RMQMessage "EXIT" "EXIT" "asgs_main.sh>sigterm()" "EXIT" "Received SIGTERM.  Shutting ASGS down ..." 
   allMessage "Received SIGTERM. Shutting ASGS instance $INSTANCENAME down."
   trap - SIGTERM && kill -- -$$ # "untrap" SIGTERM and send SIGTERM to all processes in this process group 
   exit 0
}
#
# send message when shutting down on EXIT and clear all processes
sigexit() {
   RMQMessage "EXIT" "EXIT" "asgs_main.sh>sigiexit()" "EXIT" "Received SIGEXIT.  Shutting ASGS down ..." 
   allMessage "Received SIGEXIT.  Shutting ASGS instance $INSTANCENAME down."
   trap - SIGTERM && kill -- -$$ # "untrap" SIGTERM and send SIGTERM to all processes in this process group 
   exit 0
}
#
# set up logging so that output from various processes within a scenario 
# is also sent to scenario.log file for centralized logging
initCentralizedScenarioLogging() {
   unset logFiles
   unset subshellPIDs
   if [[ "$JOBTYPE" =~ prep || $JOBTYPE = partmesh ]]; then
      logFiles=( fort.6 fort.16 ${JOBTYPE}.out )
   fi
   if [[ $JOBTYPE = padcirc ]]; then
      logFiles=( fort.6 fort.16 adcirc.log ${JOBTYPE}.out )
   fi
   if [[ $JOBTYPE = padcswan ]]; then
      logFiles=( fort.6 fort.16 adcirc.log PE0000/asgs_swan.prt PE0000/Errfile  ${JOBTYPE}.out )
   fi
   #
   # initialize log files if they do not exist so tail doesn't exit immediately
   for file in ${logFiles[*]} ; do
      echo "Initializing $file file." | awk -v level=INFO -v this="logging.sh" -f $SCRIPTDIR/monitoring/timestamp.awk >> scenario.log 2>&1
      if [[ -e $file ]]; then
         rm $file
      fi
      # make a zero length file
      touch $file
      # execute logs monitoring in the background
      (
         tail -f $file >> scenario.log 2>&1
      ) &
      # add this process ID to the list of background subshell jobs
      subshellPIDs+=($!)
   done
   # write the logging PIDs to the run.properties file so they can be 
   # cleaned up later
   SUBSHELLPIDSTRING="("
   for string in ${subshellPIDs[*]}; do
      SUBSHELLPIDSTRING="$SUBSHELLPIDSTRING $string"
   done
   SUBSHELLPIDSTRING="$SUBSHELLPIDSTRING )"
   echo "hpc.job.${JOBTYPE}.subshellpids : $SUBSHELLPIDSTRING" >> $STORMDIR/run.properties   
}
#
# terminate centralized logging subshell processes
finalizeCentralizedScenarioLogging() {
   unset subshellPIDs
   # grab list of associated subshell PIDs from run.properties file
   declare -a subshellPIDs=`grep hpc.job.$JOBTYPE.subshellpids run.properties | cut -d':' -f 2- | sed -n 's/^\s*//p'`
   # loop over subshell processes 
   for pid in ${subshellPIDs[*]}; do
      # terminate each one
      echo "Terminating previously spawned subshell process ID ${pid}." | awk -v level=INFO -v this=logging.sh -f $SCRIPTDIR/monitoring/timestamp.awk >> scenario.log 2>&1
      kill -TERM $pid 2>&1 | awk -v this=logging.sh -v level=INFO -f $SCRIPTDIR/monitoring/timestamp.awk >> scenario.log 2>&1
   done
   unset subshellPIDs  
}
#
# Find and clear stray orphan tail -f processes that have not been cleaned
# up. Normally there should not be any stray orphan processes, but there
# could be, and we want to avoid a proliferation of orphan processes. 
findAndClearOrphans() {
   #
   # send SIGTERM to tail processes owned by this Operator that are children
   # of init (i.e., process)
   for pid in `ps -eo pid,ppid,user,comm | awk -v user=$USER '$3==user && $2==1 && $4~/tail/ { print $1 } '`; do
      logMessage "Found orphan 'tail -f' process ID $pid and now clearing it." 
      kill $pid 
   done
}
#
#
function IncrementNCEPCycle()
{
	local DATE='date --utc'
	local inc=21600  # cycle increment in secs

	if [  $# -eq 0 ] ; then
		d=`$DATE +%Y%m%d%H`
		cy=${d:8:2}
		cy=`echo "6*($cy/6)" | bc`
	else
		d=$1
	fi

	if [ ${#d} -lt 10 ] ; then
		echo input date must of YYYYMMDDHH
		exit 1
	fi

	#cy=${d:8:2}
	#cy=`echo "6*($cy/6)" | bc`
	#echo $d, $cy
	#echo Current NCEP Cycle = $cy

	# input YYMMDDHH in epoch seconds
	d1=`$DATE -d "${d:0:4}-${d:4:2}-${d:6:2} ${d:8:2}:00:00" +%s`
	d2=$[$d1+$inc]
	d2=`$DATE -d "1970-01-01 UTC $d2 seconds" +%Y%m%d%H`
	cy=${d2:8:2}
	cy=`echo "6*(${d2:8:2}/6)" | bc`
	d2=`printf "${d2:0:8}%02d" $cy`
	echo $d2
	#echo Next NCEP Cycle = $cy
}
#
#
RMQMessageStartup() 
{ 
  if [[ ${RMQMessaging_Enable} == "off" ]] ; then return; fi
  DATETIME=`date --utc +'%Y-%h-%d-T%H:%M:%S'`
  FILE2SEND=$1
  ${RMQMessaging_Python} ${RMQMessaging_StartupScript} \
         --Uid $$ \
         --LocationName ${RMQMessaging_LocationName} \
         --ClusterName ${RMQMessaging_ClusterName} \
         --Message "$FILE2SEND"  \
         --InstanceName $INSTANCENAME \
         --Transmit ${RMQMessaging_Transmit} >> $SYSLOG 2>&1
}
#
#
RMQMessage()  # MTYPE EVENT PROCESS STATE MSG PCTCOM
{ 
  if [[ ${RMQMessaging_Enable} == "off" ]] ; then return; fi

  DATETIME=`date --utc +'%Y-%h-%d-T%H:%M:%S'`
  MTYPE=$1
  EVENT=$2
  PROCESS=$3
  STATE=$4
  MSG=$5
  #MSG="RMQ-$MTYPE : $EVENT : $STATE : ${DATETIME} : $MSG"
  PCTCOM=0
  if [ "$#" -eq 6 ] ; then PCTCOM=$6 ; fi

  if [[ $RMQADVISORY -lt 0 ]] ; then
	echo "warn: RMQA ($RMQADVISORY) < 0.  Not sending message ..."
	return
  fi

  re='^[0-9]+([.][0-9]+)?$' 
  if ! [[ $PCTCOM =~ $re ]] ; then
      echo "warn: PCTCOM ($PCTCOM) not a number in RMQMessage.  Not sending message ..." 
  else
     printf "RMQ : %s : %10s : %4s : %4s : %21s : %4s : %5.1f : %s : %s\n" ${INSTANCENAME} ${RMQADVISORY} ${MTYPE} ${EVENT} ${DATETIME} ${STATE} ${PCTCOM} ${PROCESS}  "$5"

     # Send message to RabbitMQ queue.  The queue parameters are in the asgs_msgr.py code
     ${RMQMessaging_Python} ${RMQMessaging_Script} \
         --Uid $$ \
         --LocationName ${RMQMessaging_LocationName} \
         --ClusterName ${RMQMessaging_ClusterName} \
         --StormNumber $STORM \
         --StormName $STORMNAME \
         --AdvisoryNumber $RMQADVISORY \
         --Message "$MSG"  \
         --EventType $EVENT \
         --Process $PROCESS \
         --PctComplete 0 \
         --SubPctComplete $PCTCOM \
         --State $STATE \
         --RunParams $RMQRunParams \
         --InstanceName $INSTANCENAME \
         --Transmit ${RMQMessaging_Transmit} >> ${SYSLOG} 2>&1
   fi
}
#
# write an INFO-level message to the main asgs log file
logMessage()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] INFO: $@"
  echo ${MSG} >> ${SYSLOG}
}
#
# write an INFO-level message to the cycle (or advisory log file)
cycleMessage()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] INFO: $@"
  if [[ -e $ADVISDIR/cycle.log ]]; then
     echo ${MSG} >> $ADVISDIR/cycle.log
  fi
}
#
# write an INFO-level message to the cycle (or advisory log file)
scenarioMessage()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] INFO: $@"
  if [[ -e $ADVISDIR/$ENSTORM/scenario.log ]]; then
     echo ${MSG} >> $ADVISDIR/$ENSTORM/scenario.log
  fi
}

#
# send a message to the console (i.e., window where the script was started)
# (these should be rare)
consoleMessage()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] INFO: $@"
  echo ${MSG}
}
#
# send INFO message to main asgs log file, cycle (advisory) log file, as well
# as scenario log file 
allMessage()
{
#   consoleMessage $@
   logMessage $@
   cycleMessage $@
   scenarioMessage $@
}
#
# log a warning message, execution continues
warn()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] WARNING: $@"
  for file in $SYSLOG $ADVISDIR/cycle.log $ADVISDIR/$ENSTORM/scenario.log ; do
    if [[ -e $file ]]; then
      echo ${MSG} >> ${SYSLOG}
    fi
  done
  #echo ${MSG}  # send to console
}
#
# log an error message, notify Operator 
error()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] ERROR: $@"
  echo ${MSG}  # send to console
  for file in $SYSLOG $ADVISDIR/cycle.log $ADVISDIR/$ENSTORM/scenario.log ; do
    if [[ -e $file ]]; then
      echo ${MSG} >> ${SYSLOG}
    fi
  done
  # email the operator
  if [[ $EMAILNOTIFY = yes || $EMAILNOTIFY = YES ]]; then
     echo $MSG | mail -s "[ASGS] Attn: Error for $INSTANCENAME" "${ASGSADMIN}"
  fi 
}
#
# log an error message, execution halts
fatal()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] FATAL ERROR: $@"
  for file in $SYSLOG $ADVISDIR/cycle.log $ADVISDIR/$ENSTORM/scenario.log ; do
    if [[ -e $file ]]; then
      echo ${MSG} >> ${SYSLOG}
    fi
  done
  if [[ $EMAILNOTIFY = yes || $EMAILNOTIFY = YES ]]; then
     cat ${SYSLOG} | mail -s "[ASGS] Fatal Error for PROCID ($$)" "${ASGSADMIN}"
  fi
  echo ${MSG} # send to console
  exit ${EXIT_NOT_OK}
}
#
# log a debug message
debugMessage()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S%z'`
  MSG="[${DATETIME}] DEBUG: $@"
  echo ${MSG} >> $ADVISDIR/$ENSTORM/scenario.log
}
