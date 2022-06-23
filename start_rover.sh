#!/bin/bash

#set this to true if both rover & station are connected to the one pi
UNITEDDEVICE=1

TS=`date +%Y%m%d-%H%M`
STR2STR=str2str
GNSSRTKLOC=../../..
LOGFOLDER=logs_for_modified_scripts

BASE=$1
DEVICE=ttyACM$2

if [ "$#" -ne 2 ]; then
        echo "./start_rover.sh <base-station-ip> <device-port-number>"
        exit 1
fi

BASESTATION_RTC3OUT=21101
LOCALHOST_OBSVOUT=21102
LOCALHOST_PVTOUT=21103

if [ ${UNITEDDEVICE} -eq 1 ]; then
    echo "Running as though rover & base station are on the same pi"
else
    echo "Running as though rover & base station are on different pis";
    BASESTATION_RTC3OUT=21101
fi

# Read RTCM from base station and send to GNSS receiver
echo "Piping RTCM into rover GNSS receiver"
${STR2STR} -in tcpcli://${BASE}:BASESTATION_RTC3OUT -out file://dev/${DEVICE} >& ${LOGFOLDER}/rover-rtcm-in-${TS}.log &
sleep 2

# Make roving GNSS data available
echo "Publishing rover GNSS observations on port ${LOCALHOST_OBSVOUT}"
${STR2STR} -in serial://${DEVICE}:230400 -out tcpsvr://:${LOCALHOST_OBSVOUT} -c ./${GNSSRTKLOC}/ublox_f9p/cfg_f9p_rover.cmd >& ${LOGFOLDER}/rover-tcpsrv-${TS}.log &
sleep 2

# Make PVT stream available
echo "Publishing rover PVT on port ${LOCALHOST_PVTOUT}"
netcat localhost ${LOCALHOST_OBSVOUT} |  ${GNSSRTKLOC}/src/ubx/ubx_nav_pvt | ${STR2STR} -out tcpsvr://:${LOCALHOST_PVTOUT} >& ${LOGFOLDER}/rover-PVT-out-${TS}.log &

# Channel rover NMEA to Raspberry Pi Sensehat LED blinker
#netcat localhost ${LOCALHOST_OBSVOUT} | ${GNSSRTKLOC}/ublox_m8p/sense_hat_indicator >& ${LOGFOLDER}/rover-blink-${TS}.log &

#netcat localhost ${LOCALHOST_OBSVOUT} > ${LOGFOLDER}/rover-${TS}.ubx &

# PVT service
#netcat localhost ${LOCALHOST_OBSVOUT} | ${GNSSRTKLOC}/src/ubx/ubx_nav_pvt | ${STR2STR} -out tcpsvr://:${LOCALHOST_PVTOUT}

# Gamepad
#${GNSSRTKLOC}/src/util/gamepad_events /dev/input/event0 | ${STR2STR} -out tcpsvr://:21104
