#!/bin/bash

#Set true if both rover & base station are connected to the same pi.
UNITEDDEVICE=1

TS=`date +%Y%m%d-%H%M`

SURVEY_ACCURACY_M=10
SURVEY_MIN_TIME_S=120

GNSS_PATH=/home/pi/GNSS_RTK
LOG_PATH=/home/pi/GNSS_RTK/ublox_f9p/oisins_branch/rtklib_basics/logs_for_modified_scripts

if [ "$#" -ne 1 ]; then
    echo "./start_base_station <device-port-number>"
    exit 1
fi

RTCM3OUT=21101
RAWOUT=21104

DEV=ttyACM$1

if [ ${UNITEDDEVICE} -eq 1 ]; then
    echo "Running as though rover & station are on the same pi"
else
    echo "Running as though rover & station are on different pis"
    RTCM3OUT=21103
    RAWOUT=21102
fi

${GNSS_PATH}/src/ubx/ubx_cfg_tmode3 $SURVEY_MIN_TIME_S $SURVEY_ACCURACY_M -b > /dev/${DEV}

echo "Starting raw data streaming on port $RAWOUT"

str2str -in serial://${DEV}:230400#ubx -out tcpsvr://:${RAWOUT} -c ${GNSS_PATH}/ublox_f9p/cfg_f9p_basestation.cmd >& ${GNSS_PATH}/ublox_f9p/oisins_branch/rtklib_basics/logs_for_modified_scripts/base-${TS}.log &

sleep 1

echo "Starting RTCM3 server on port $RTCM3OUT"

netcat localhost ${RAWOUT} | ${GNSS_PATH}/src/rtcm3_filter | str2str -out tcpsvr://:${RTCM3OUT} >& ${GNSS_PATH}/ublox_f9p/oisins_branch/rtklib_basics/logs_for_modified_scripts/base-rtcm-${TS}.log &
