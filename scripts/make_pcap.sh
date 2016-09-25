#!/bin/bash

# this script changes the file name
# old file name: tcp_dump_gateway0.pcap_Sat_Aug__6_01-40-19_UTC_2016
# new file name: tcp_dump_gateway0_Sat_Aug__6_01-40-19_UTC_2016.pcap
# so that we can open the files in wireshark
# specify the path to the folder where it containts pcap files
# Usage example 
# ./make_pcap.sh /Users/xxxx/Desktop/08-05-2016/test_folder/tcp_dump

FILES=${1}/*
for filename in $FILES
do
  #echo $filename
  searchstring="pcap"
  
  rest=${filename#*$searchstring} 
  if [ "$rest" != "$filename" ]
  then  
      rest+=".pcap"
      new_filename=${filename%.*} 
      new_filename+=${rest}
      mv $filename ${new_filename}
  fi
done
