#!/bin/bash

#set this to true if both rover & station are connected to the one pi
UNITEDDEVICE=1

TS=`date +%Y%m%d-%H%M`

GNSS_PATH=/home/pi/GNSS_RTK
LOG_PATH=/home/pi/GNSS_RTK/ublox_f9p/oisins_branch/rtklib_basics/logs_for_modified_scripts

if [ "$#" -ne 2 ]; then
    echo "./start_rover.sh <base-station-ip> <device-port-number>"
    exit 1
fi

RTCM3OUT=21101
OBSVOUT=21102
PVTOUT=21103

BASE_IP=$1
DEV=ttyACM$2

if [ ${UNITEDDEVICE} -eq 1 ]; then
    echo "Running as though rover & base station are on the same pi"
else
    echo "Running as though rover & base station are on different pis";
    RTCM3OUT=21103
fi

echo "Piping RTCM3 into rover GNSS receiver"
str2str -in tcpcli://${BASE_IP}:${RTCM3OUT} -out file://dev/${DEV} >& ${LOG_PATH}/rover-rtcm-in-${TS}.log &
sleep 2

echo "Publishing rover GNSS observations on port ${OBSVOUT}"
str2str -in serial://${DEV}:230400 -out tcpsvr://:${OBSVOUT} -c ${GNSS_PATH}/ublox_f9p/cfg_f9p_rover.cmd >& ${LOG_PATH}/rover-tcpsrv-${TS}.log &
sleep 2

echo "Publishing rover PVT on port ${PVTOUT}"
netcat localhost ${OBSVOUT} |  ${GNSS_PATH}/src/ubx/ubx_nav_pvt | str2str -out tcpsvr://:${PVTOUT} >& ${LOG_PATH}/rover-PVT-out-${TS}.log &
