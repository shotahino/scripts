#!/bin/bash

URL="www.yahoo.com"
numRoams=0
noRoam=0
firstTime=1

while :; do

hostReachable=""
hostReachable=`curl -s $URL | grep HEAD`
bssid=`airport -I | grep BSSID | cut -d : -f 2-7`

if [[ -z $hostReachable ]] ; then
echo Host not reachable `date`
fi

if ! [[ $firstTime == 1 ]] ; then
if ! [[ "$bssid" == "$oldBssid" ]] ; then

numRoams=`echo "$numRoams + 1" | bc`
echo "BSSID changed, $oldBssid $bssid,  `date`, numRoams $numRoams"

elif [[ "$bssid" == "$oldBssid" ]] ; then

noRoam=`echo "$noRoam + 1" | bc`

else
echo error error error
fi

elif [[ $firstTime == 1 ]] ; then
echo BSSID $bssid
fi

firstTime=0
oldBssid=$bssid


sleep 1
done
