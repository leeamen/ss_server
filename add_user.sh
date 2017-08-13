#!/bin/bash
if [ $# -ne 1 ];then
    echo "$0 端口"
    exit
fi

function checkPort()
{
    port=$1
    res=$(netstat -natp|grep $port)
    if [ -n "${res}" ];then
        echo "1"
    else
        echo "0"
    fi
}

err_log="error.log"
#启动容器
port=$1
res=$(checkPort $port)
if [ $res -eq 1 ];then
    echo "端口:${port}已经使用"|tee -a $err_log
    exit
fi

container_id=$(docker run -d -p ${port}:${port} oddrationale/docker-shadowsocks -s 0.0.0.0 -p $port -k "4zqwz#g7" -m aes-256-cfb)

#添加iptables监控流量
ip=$(ps -ef|grep "docker-proxy"|grep "${port}"|awk '{print $16}')
if [ -z "${ip}" ];then
    echo "启动失败,port:${port}!"| tee -a $err_log
    exit
fi

#设置流量监控
iptables -A FORWARD -p tcp -s $ip
iptables -A FORWARD -p tcp -d $ip
iptables -nvL

#保存配置
echo $ip >> user_list
iptables-save > iptab.save

echo "添加成功,container_id:${container_id}"

