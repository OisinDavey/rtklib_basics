#!/bin/bash

TS=`date +%Y%m%d-%H%M`
#STR2STR=/home/pi/RTKLIB/app/consapp/str2str/gcc/str2str
STR2STR=str2str

BASE=$1
DEVICE=ttyACM$2
LOGFOLDER=logs_for_modified_scripts

if [ "$#" -ne 2 ]; then
        echo "./start_rover.sh <base-station-ip> <device-port-number> (usually 0)"
        exit 1
fi

echo ${DEVICE}

# Read RTCM from base station and send to GNSS receiver
echo "Piping RTCM into rover GNSS receiver"
${STR2STR} -in tcpcli://${BASE}:21101 -out file://dev/${DEVICE} >& ${LOGFOLDER}/rover-rtcm-in-${TS}.log &
sleep 2

# Make roving GNSS data available
echo "Publishing rover GNSS observations on port 21102"
${STR2STR} -in serial://${DEVICE}:230400 -out tcpsvr://:21102 -c ./cfg_f9p_rover.cmd >& ${LOGFOLDER}/rover-tcpsrv-${TS}.log &
sleep 2

# PVT messages only on 21103 (for bandwidth efficiency)
echo "Publishing rover PVT on port 21103"
netcat localhost 21102 |  ../src/ubx/ubx_nav_pvt | ${STR2STR} -out tcpsvr://:21103 >& ${LOGFOLDER}/rover-PVT-out-${TS}.log &

# Channel rover NMEA to Raspberry Pi Sensehat LED blinker
#netcat localhost 21102 | /home/pi/GNSS_RTK/ublox_m8p/sense_hat_indicator >& ${LOGFOLDER}/rover-blink-${TS}.log &

netcat localhost 21102 > ${LOGFOLDER}/rover-${TS}.ubx &


# PVT service
#netcat localhost 21102 | ../src/ubx/ubx_nav_pvt | ${STR2STR} -out tcpsvr://:21103

# Gamepad
#../src/util/gamepad_events /dev/input/event0 | ${STR2STR} -out tcpsvr://:21104
