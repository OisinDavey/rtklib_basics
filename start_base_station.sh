#!/bin/bash

#set to true if both rover & base station are connected to the one pi
UNITEDDEVICE=1

TS=`date +%Y%m%d-%H%M`
STR2STR=str2str
GNSSRTKLOC=../../..
LOGFOLDER=logs_for_modified_scripts

DEVICE=ttyACM$1

SURVEY_ACCURACY_M=10
SURVEY_MIN_TIME_S=120

if [ "$#" -ne 1 ]; then
    echo "./start_base_station <device-port-number>"
    exit 1
fi

LOCALHOST_RAWOUT=21104
LOCALHOST_RTCM3OUT=21101

if [ ${UNITEDDEVICE} -eq 1 ]; then
    echo "Running as though rover & station are on the same pi"
else
    echo "Running as though rover & station are on different pis"
    LOCALHOST_RAWOUT=21102
    LOCALHOST_RTCM3OUT=21101
fi

${GNSSRTKLOC}/src/ubx/ubx_cfg_tmode3 $SURVEY_MIN_TIME_S $SURVEY_ACCURACY_M -b > /dev/${DEVICE}

echo "Starting raw data streaming on port ${LOCALHOST_RAWOUT}"
${STR2STR} -in serial://${DEVICE}:230400#ubx -out tcpsvr://:${LOCALHOST_RAWOUT} -c ./${GNSSRTKLOC}/cfg_f9p_basestation.cmd >& ${LOGFOLDER}/base-${TS}.log &
sleep 1
netcat localhost ${LOCALHOST_RAWOUT} > ${LOGFOLDER}/base-${TS}.ubx &

# Make RTCM3 available on port ${LOCALHOST_RTCM3OUT}
echo "Starting RTCM3 server on port ${LOCALHOST_RTCM3OUT}"
netcat localhost ${LOCALHOST_RTCM3OUT} | ./${GNSSRTKLOC}/src/rtcm3_filter | ${STR2STR} -out tcpsvr://:${LOCALHOST_RTCM3OUT} >& ${LOGFOLDER}/base-rtcm-${TS}.log &
