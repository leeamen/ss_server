#!/bin/bash
#添加forward规则
#iptables -A -p tcp -s ip
#iptables -A -p tcp -d ip


function isNumber()
{
    res=$(echo $1| awk '{print($0~/^[-]?([0-9])+[.]?([0-9])+$/)?"number":"string"}')
    if [ "${res}" = "string" ];then
        echo 1
    else
        echo 0
    fi
}


#获取用户信息:消耗 是否超限(1:超限)
function statiUserInfo()
{
    user_ip=$1
    limit=$2
    iptables -nv -L FORWARD -x --line-numbers|grep "${user_ip}"|awk -v limit=${limit} '
    BEGIN{trans = 0.;stat=0}
    {#print $3;
    trans += $3}
    END{trans /= (1024 * 1024)
    #流量超50G
    if(trans > limit) stat=1
    printf "%f %d\n", trans, stat
    }'
}

function monitorByUserFile()
{
    user_file=$1
    while read line
    do
        user_ip=$(echo $line|awk '{print $1}')
        limit=$(echo $line|awk '{print $3}')
        echo "$user_ip, ${limit}"
        res=$(statiUserInfo $user_ip $limit)
        trans=$(echo "$res"|awk '{print $1}')
        stat=$(echo "$res"|awk '{print $2}')
        echo "用户:${user_ip}, 消耗流量:${trans}MB,限制:${limit}MB"
        if [ $stat -eq 1 ];then
            port=$(ps -ef|grep docker|grep "${user_ip}"|awk '{print $NF}')
            res=$(isNumber $port)
            if [ $res -eq 1 ];then
                #进程不在,可能已经关闭
                echo "不存在:${user_ip} 绑定的container"| tee -a "${log_file}"
            else
                container_id=$(docker ps|grep ${port}|awk '{print $1}')
                echo "流量超限,关闭container:${container_id},端口:${port}"|tee -a "${log_file}"
                docker stop ${container_id}
            fi
        fi
        sleep 1
    done < ${user_file}
}

if [ $# -ne 1 ];then
    echo "$0 ip列表文件"
    exit
fi

#日志文件
log_file="$(date +%Y%m%d).log"

user_file="$1"
while true
do
    monitorByUserFile $user_file
    sleep 30
    #clear
done
