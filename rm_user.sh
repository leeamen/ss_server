#!/bin/bash

if [ $# -ne 2 ];then
    echo "$0 ip port"
    exit
fi

ip=$1
port=$2
userfile="user_list"

iptables -nv -L FORWARD
iptables -D FORWARD -p tcp -d $ip
iptables -D FORWARD -p tcp -s $ip
iptables -nv -L FORWARD
echo "清除iptables表项"

#删除docker
container_id=$(cat $userfile|grep "$port"|awk '{print $4}')
docker rm $container_id
echo "成功删除container:${container_id}"
