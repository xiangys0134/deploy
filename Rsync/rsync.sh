#!/bin/bash
#ubuntu rsync 日志同步
#Author: yousong.xiang
#Date:  2018.11.28
#Version: v1.0.1

[ -f /etc/profile ] && . /etc/profile

cmd=`dirname $0`

function rsync_log() {
    #示例：rsync -vzrt -P --delete rsync_backup@172.4.0.12::tb03_184_log /BETA-log/tb03_184_log --password-file=/etc/rsyncd.pas
    #$1------> 172.4.0.12
    #$2------> rsync_backup
    #$3------> /etc/rsyncd.pas
    #$4------> tb03_184_log
    #$5------> /BETA-log/tb03_184_log
    rsync_ip=$1
    rsync_user=$2
    rsync_pass_file=$3
    rsync_mod=$4
    dsc_directory=$5
    #rsync -vzrt -P --delete ${rsync_user}@${rsync_ip}::${rsync_mod} ${dsc_directory} --password-file=${rsync_pass_file}
    rsync -vzrt -P ${rsync_user}@${rsync_ip}::${rsync_mod} ${dsc_directory} --password-file=${rsync_pass_file}
}

pass_file=/etc/rsyncd.pas
user=rsync_backup
base_dir=/release-log

################################################################release web机01#############################################################
server_ip=172.16.143.140
server_mode="
web_140_bms
web_140_ipb
web_140_irs
web_140_oms
web_140_rms
web_140_utility
web_140_pms
web_140_uds
web_140_pm2
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    rsync_log "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################release web机02#############################################################
server_ip=172.16.143.139
server_mode="
web_139_bms
web_139_ipb
web_139_irs
web_139_oms
web_139_rms
web_139_utility
web_139_pms
web_139_uds
web_139_pm2
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    rsync_log "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################release 脚本机#############################################################
server_ip=172.16.143.138
server_mode="
script_138_bms
script_138_ipb
script_138_irs
script_138_oms
script_138_rms
script_138_utility
script_138_pms
script_138_uds
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    rsync_log "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################release tb01#############################################################
server_ip=10.80.60.135
server_mode="
tb_135_log
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    rsync_log "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################release tb02#############################################################
server_ip=10.27.99.143
server_mode="
tb_143_log
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    rsync_log "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################release tb03#############################################################
server_ip=172.16.106.43
server_mode="
tb_43_log
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    rsync_log "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done

################################################################release tb04#############################################################
server_ip=10.30.200.93
server_mode="
tb_93_log
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    rsync_log "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done

