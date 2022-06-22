#!/bin/bash
TS=`date +%Y%m%d-%H%M`
STR2STR=str2str
DEVICE=ttyACM$1
SURVEY_ACCURACY_M=10
SURVEY_MIN_TIME_S=120

if [ "$#" -ne 1 ]; then
        echo "./start_base_station <device-port-number>"
        exit 1
fi

#echo ${DEVICE}

../src/ubx/ubx_cfg_tmode3 $SURVEY_MIN_TIME_S $SURVEY_ACCURACY_M -b > /dev/${DEVICE}

echo "Starting raw data streaming on port 21104"
${STR2STR} -in serial://${DEVICE}:230400#ubx -out tcpsvr://:21104 -c ./cfg_f9p_basestation.cmd >& base-${TS}.log &
sleep 1
netcat localhost 21102 > base-${TS}.ubx &

# Make RTCM3 available on port 21101
echo "Starting RTCM3 server on port 21101"
netcat localhost 21104 | ./../src/rtcm3_filter | ${STR2STR} -out tcpsvr://:21101 >& base-rtcm-${TS}.log &
