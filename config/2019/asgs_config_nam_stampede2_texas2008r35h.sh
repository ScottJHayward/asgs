#!/bin/sh
#-------------------------------------------------------------------
# config.sh: This file is read at the beginning of the execution of the ASGS to
# set up the runs  that follow. It is reread at the beginning of every cycle,
# every time it polls the datasource for a new advisory. This gives the user
# the opportunity to edit this file mid-storm to change config parameters
# (e.g., the name of the queue to submit to, the addresses on the mailing list,
# etc)
#-------------------------------------------------------------------
#
# Copyright(C) 2019 Jason Fleming
#
# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# ASGS is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------

# Fundamental

INSTANCENAME=readytx      # "name" of this ASGS process
COLDSTARTDATE=2019051000  # calendar year month day hour YYYYMMDDHH24
HOTORCOLD=coldstart        # "hotstart" or "coldstart"
LASTSUBDIR=null
HINDCASTLENGTH=30.0       # length of initial hindcast, from cold (days)
REINITIALIZESWAN=no       # used to bounce the wave solution

# Source file paths

ADCIRCDIR=$WORK/adcirc-cg/jasonfleming/v53release/work # ADCIRC executables
SWANDIR=$WORK/adcirc-cg/jasonfleming/v53release/swan   # ADCIRC executables
SCRIPTDIR=$WORK/asgs/jasonfleming/master               # ASGS executables
INPUTDIR=${SCRIPTDIR}/input/meshes/texas2008_r35h      # grid and other input files
OUTPUTDIR=${SCRIPTDIR}/output # post processing scripts

# Physical forcing

BACKGROUNDMET=on      # NAM download/forcing
TIDEFAC=on            # tide factor recalc
TROPICALCYCLONE=off   # tropical cyclone forcing
WAVES=off              # wave forcing
VARFLUX=off           # variable river flux forcing

# Computational Resources

TIMESTEPSIZE=1.0             # adcirc time step size (seconds)
SWANDT=1200                  # swan time step size (seconds)
HINDCASTWALLTIME="18:00:00"  # hindcast wall clock time
ADCPREPWALLTIME="01:30:00"   # adcprep wall clock time, including partmesh
NOWCASTWALLTIME="08:00:00"   # longest nowcast wall clock time
FORECASTWALLTIME="05:00:00"  # forecast wall clock time
NCPU=479                     # number of compute CPUs for all simulations
NCPUCAPACITY=3648
NUMWRITERS=1
CYCLETIMELIMIT="99:00:00"

# External data sources : Tropical cyclones

STORM=99                         # storm number, e.g. 05=ernesto in 2006
YEAR=2016                        # year of the storm
TRIGGER=rssembedded              # either "ftp" or "rss"
#RSSSITE=filesystem
#FTPSITE=filesystem
#FDIR=${SCRIPTDIR}/input/sample_advisories
#HDIR=${SCRIPTDIR}/input/sample_advisories
RSSSITE=www.nhc.noaa.gov         # site information for retrieving advisories
FTPSITE=ftp.nhc.noaa.gov         # hindcast/nowcast ATCF formatted files
FDIR=/atcf/afst                  # forecast dir on nhc ftp site
HDIR=/atcf/btk                   # hindcast dir on nhc ftp site

# External data sources : Background Meteorology

FORECASTCYCLE="06"
BACKSITE=ftp.ncep.noaa.gov          # NAM forecast data from NCEP
BACKDIR=/pub/data/nccf/com/nam/prod # contains the nam.yyyymmdd files
FORECASTLENGTH=84                   # hours of NAM forecast to run (max 84)
PTFILE=ptFile_oneEighth.txt         # the lat/lons for the OWI background met
ALTNAMDIR="/projects/ncfs/data/asgs5463","/projects/ncfs/data/asgs14174"
SPATIALEXTRAPOLATIONRAMP=yes
SPATIALEXTRAPOLATIONRAMPDISTANCE=5.0

# External data sources : River Flux

RIVERSITE=ftp.nssl.noaa.gov
RIVERDIR=/projects/ciflow/adcirc_info

# Input files and templates

GRIDFILE=tx2008_r35h.grd # mesh (fort.14) file
GRIDNAME=tx2008_r35h
MESHPROPERTIES=${GRIDFILE}.properties
CONTROLTEMPLATE=tx2008r35h_template.15   # fort.15 template
CONTROLPROPERTIES=${CONTROLTEMPLATE}.properties
ELEVSTATIONS=tx2008r35h_stations_20170618.txt
VELSTATIONS=tx2008r35h_stations_20170618.txt
METSTATIONS=tx2008r35h_stations_20170618.txt
NAFILE=tx2008_r35h.13
NAPROPERTIES=${NAFILE}.properties
SWANTEMPLATE=nolimiter.fort.26.ut.template    # only used if WAVES=on
RIVERINIT=null                           # this mesh has no rivers ...
RIVERFLUX=null
HINDCASTRIVERFLUX=null
PREPPEDARCHIVE=prepped_${GRIDNAME}_${INSTANCENAME}_${NCPU}.tar.gz
HINDCASTARCHIVE=prepped_${GRIDNAME}_hc_${INSTANCENAME}_${NCPU}.tar.gz

# Output files

# water surface elevation station output
FORT61="--fort61freq 300.0 --fort61netcdf" 
# water current velocity station output
FORT62="--fort62freq 0"                    
# full domain water surface elevation output
FORT63="--fort63freq 3600.0 --fort63netcdf" 
# full domain water current velocity output
FORT64="--fort64freq 3600.0 --fort64netcdf" 
# met station output
FORT7172="--fort7172freq 3600.0 --fort7172netcdf"           
# full domain meteorological output
FORT7374="--fort7374freq 3600.0 --fort7374netcdf"           
#SPARSE="--sparse-output"
SPARSE=""
NETCDF4="--netcdf4"
OUTPUTOPTIONS="${SPARSE} ${NETCDF4} ${FORT61} ${FORT62} ${FORT63} ${FORT64} ${FORT7172} ${FORT7374}"
# fulldomain or subdomain hotstart files
HOTSTARTCOMP=fulldomain                    
# binary or netcdf hotstart files
HOTSTARTFORMAT=netcdf                      
# "continuous" or "reset" for maxele.63 etc files
MINMAX=reset                               

# Notification

EMAILNOTIFY=yes         # yes to have host HPC platform email notifications
NOTIFY_SCRIPT=ut-nam-notify.sh
ACTIVATE_LIST=null
NEW_ADVISORY_LIST=null
POST_INIT_LIST=null
POST_LIST=null
JOB_FAILED_LIST="jason.g.fleming@gmail.com"
NOTIFYUSER=jason.g.fleming@gmail.com
ASGSADMIN=jason.g.fleming@gmail.com

# RMQ Messaging
# (use defaults from platforms.sh)

# Post processing and publication

INTENDEDAUDIENCE=general
INITPOST=null_init_post.sh
POSTPROCESS=cera_post.sh
POSTPROCESS2=null_post.sh

# opendap
TDS=(tacc_tds lsu_tds renci_tds)
TARGET=stampede2  # used in post processing to pick up HPC platform config
# You must first have your ssh public key in ~/.ssh/authorized_keys2 file 
# on the opendap server machine in order to scp files there via
# opendap_post.sh. OPENDAPHOST is set to each value in the TDS array specified
# above and used by your post processing script to successively trigger 
# configuration via platforms.sh. The OPENDAPUSER parameter needs to be set
# here, rather than in platforms.sh or your post processing script,
# because multiple Operators may be posting to a particular opendap server
# using different usernames. 
OPENDAPUSER=ncfs         # default value that works for RENCI opendap 
if [[ $OPENDAPHOST = "fortytwo.cct.lsu.edu" ]]; then
   OPENDAPUSER=jgflemin  # change this for other Operator running on queenbee
fi
if [[ $OPENDAPHOST = "adcircvis.tacc.utexas.edu" ]]; then
   OPENDAPUSER=jgflemin  # change this for other Operator running on queenbee
fi
# OPENDAPNOTIFY is used by opendap_post.sh and could be regrouped with the 
# other notification parameters above. 
#OPENDAPNOTIFY="asgs.cera.lsu@gmail.com,jason.g.fleming@gmail.com,zbyerly@cct.lsu.edu"
OPENDAPNOTIFY="asgs.cera.lsu@gmail.com,jason.g.fleming@gmail.com"

# Archiving

ARCHIVE=enstorm_pedir_removal.sh
ARCHIVEBASE=/corral-tacc/utexas/hurricane/ASGS/2019
ARCHIVEDIR="nam"

# Forecast ensemble members

RMAX=default
PERCENT=default
ENSEMBLESIZE=2 # number of storms in the ensemble
case $si in
-1)
      # do nothing ... this is not a forecast
   ;;
1)
   ENSTORM=namforecast
   ;;
0)
   ENSTORM=namforecastWind10m
   ADCPREPWALLTIME="00:20:00"  # adcprep wall clock time, including partmesh
   FORECASTWALLTIME="00:20:00" # forecast wall clock time
   CONTROLTEMPLATE=tx2008r35h_norough_template.15
   CONTROLPROPERTIES=${CONTROLTEMPLATE}.properties
   TIMESTEPSIZE=300.0    # 5 minute time steps
   NCPU=47               # dramatically reduced resource requirements
   NUMWRITERS=1          # multiple writer procs might collide
   WAVES=off             # deactivate wave forcing 
   # turn off water surface elevation station output
   FORT61="--fort61freq 0"
   # turn off water current velocity station output
   FORT62="--fort62freq 0"
   # turn off full domain water surface elevation output
   FORT63="--fort63freq 0"
   # turn off full domain water current velocity output
   FORT64="--fort64freq 0"
   # met station output
   FORT7172="--fort7172freq 300.0 --fort7172netcdf"
   # full domain meteorological output
   FORT7374="--fort7374freq 3600.0 --fort7374netcdf"
   #SPARSE="--sparse-output"
   SPARSE=""
   NETCDF4="--netcdf4"
   OUTPUTOPTIONS="${SPARSE} ${NETCDF4} ${FORT61} ${FORT62} ${FORT63} ${FORT64} ${FORT7172} ${FORT7374}"
   INTENDEDAUDIENCE=general
   # prevent collisions in prepped archives
   PREPPEDARCHIVE=prepped_${GRIDNAME}_${INSTANCENAME}_${NCPU}.tar.gz
   POSTPROCESS=null_post.sh
   ;;
*)
   echo "CONFIGRATION ERROR: Unknown ensemble member number: '$si'."
   ;;
esac
