#!/bin/bash

command=""
mac=$(head -n 1 /dev/mtd4)
file_name="tcp_dump_${mac:7}_phy"

tcp_dump() {
  for i in {0..1}
  do
     command="iw phy phy${i} interface add ${1}_${i} type monitor;"
     command+="ifconfig ${1}_${i} up;"
     command+="tcpdump -XXeni ${1}_${i} -C ${2} -W 2 -w /tmp/${file_name}${i}.pcap 'type ctl or type mgt and not subtype beacon'"
     eval ${command} &
  done
}

upload_helper() {
  file=${1}
  bucket='node-tcpdump'
  resource="/${bucket}/${file}"
  contentType="application/x-compressed-tar"
  dateValue=$(date +"%a, %d %b %Y %T %z")
  stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
  s3Key="set key here"
  s3Secret="set secret here"
  signature=$(python3 /root/generate_signature.py "${s3Secret}" "${contentType}" "${dateValue}" "${resource}")
  signature=${signature:2:${#signature}-3}
  echo ${signature}

  curl -k -L -X PUT -T "${file}" \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${dateValue}" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${s3Key}:${signature}" \
    https://${bucket}.s3.amazonaws.com/${file}
}

upload() {
  rotation_file_phy0=${file_name}
  current_idx_phy0="0"
  current_size_phy0=0
  rotation_file_phy0+="0.pcap"
  s3_file_phy0=${rotation_file_phy0}
  rotation_file_phy0+=${current_idx_phy0}

  rotation_file_phy1=${file_name}
  current_idx_phy1="0"
  current_size_phy1=0
  rotation_file_phy1+="1.pcap"
  s3_file_phy1=${rotation_file_phy1}
  rotation_file_phy1+=${current_idx_phy1}

  file_size_limit=$((${1}*1000000))

  while :
  do
    sleep 5
    current_size_phy0=$(stat -c%s "/tmp/${rotation_file_phy0}")
    if [ ${current_size_phy0} -ge ${file_size_limit} ]; then
       #copy_cmd="cp /tmp/${rotation_file_phy0} /var/log/${s3_file_phy0}"
       #eval ${copy_cmd}

       #add time stamp to the file name so that it won't get overwritten
       timestamped_phy0=${s3_file_phy0}
       timestamp=$(date)
       timestamp="${timestamp// /_}"
       timestamped_phy0+="_"
       timestamped_phy0+=${timestamp}

       #upload to S3
       copy_cmd="cp /tmp/${rotation_file_phy0} ${timestamped_phy0}"
       eval ${copy_cmd}
       upload_helper ${timestamped_phy0}
       echo ${timestamped_phy0}

       #delete from node
       delete_cmd="rm ${timestamped_phy0}"
       eval ${delete_cmd}

       if [ "${current_idx_phy0}" = "0" ]; then
         current_idx_phy0="1"
       else
         current_idx_phy0="0"
       fi
       rotation_file_phy0=${file_name}
       rotation_file_phy0+="0.pcap"
       rotation_file_phy0+=${current_idx_phy0}
    fi

    current_size_phy1=$(stat -c%s "/tmp/${rotation_file_phy1}")
    if [ ${current_size_phy1} -ge ${file_size_limit} ]; then
       #copy_cmd="cp /tmp/${rotation_file_phy1} /var/log/${s3_file_phy1}"
       #eval ${copy_cmd}

       #add timestamp to the file name so that it won't get overwritten
       timestamped_phy1=${s3_file_phy1}
       timestamp=$(date)
       timestamp="${timestamp// /_}"
       timestamped_phy1+="_"
       timestamped_phy1+=${timestamp}

       #upload to S3
       copy_cmd="cp /tmp/${rotation_file_phy1} ${timestamped_phy1}"
       eval ${copy_cmd}
       upload_helper ${timestamped_phy1}
       echo ${timestamped_phy1}

       #delete from node
       delete_cmd="rm ${timestamped_phy1}"
       eval ${delete_cmd}

       if [ "${current_idx_phy1}" = "0" ]; then
         current_idx_phy1="1"
       else
         current_idx_phy1="0"
       fi
       rotation_file_phy1=${file_name}
       rotation_file_phy1+="1.pcap"
       rotation_file_phy1+=${current_idx_phy1}
    fi
  done
}

main() {
  sleep 180
  if [ "$#" -ne 2 ]; then
    echo "Usage: ./tcp_dump.sh <interface-name> <file size in MB>"
  else
    #trigger TCP dump. Second argument is the size limit
    tcp_dump ${1} ${2}
    upload ${2}
  fi
}

main "$@"
