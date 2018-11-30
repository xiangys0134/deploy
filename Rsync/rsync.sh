#!/bin/bash
#ubuntu rsync 日志同步
#Author: yousong.xiang
#Date:  2018.11.28
#Version: v1.0.1

[ -f /etc/profile ] && . /etc/profile

cmd=`dirname $0`

function beta_rsync() {
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
    rsync -vzrt -P --delete ${rsync_user}@${rsync_ip}::${rsync_mod} ${dsc_directory} --password-file=${rsync_pass_file}
}

pass_file=/etc/rsyncd.pas
user=rsync_backup
base_dir=/BETA-log

################################################################集中式web机#############################################################
server_ip=172.4.0.5
server_mode="
web_66_bms
web_66_ipb
web_66_irs
web_66_oms
web_66_rms
web_66_utility
web_66_pms
web_66_uds
web_66_pm2
web_66_est
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################集中式脚本机#############################################################
server_ip=172.4.0.6
server_mode="
script_15_bms
script_15_ipb
script_15_irs
script_15_oms
script_15_rms
script_15_utility
script_15_pms
script_15_uds
script_15_SYSTEMS
script_15_OS
script_15_est
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################集中式TB1###############################################################
server_ip=172.4.0.7
server_mode="
tb01_211_log
pbht_211_log
file_entrust_211_log
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done

################################################################集中式TB2###############################################################
server_ip=172.4.0.8
server_mode="
tb02_215_log
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done

################################################################集中式TB3###############################################################
server_ip=172.4.0.12
server_mode="
tb03_184_log
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################分布式机构端(券商版机构端web机)################################################
server_ip=172.4.0.18
server_mode="
web_238_bms
web_238_ipb
web_238_irs
web_238_oms
web_238_rms
web_238_utility
web_238_pms
web_238_uds
web_238_pm2
web_238_est
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done


################################################################分布式机构端(券商版机构端脚本机)################################################
server_ip=172.4.0.17
server_mode="
script_249_bms
script_249_ipb
script_249_irs
script_249_oms
script_249_rms
script_249_utility
script_249_pms
script_249_uds
script_249_est
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done

################################################################分布式券商端(券商版券商端web机)################################################
server_ip=172.4.0.15
server_mode="
web_210_bms
web_210_ipb
web_210_irs
web_210_oms
web_210_rms
web_210_utility
web_210_pms
web_210_uds
web_210_pm2
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done

################################################################分布式券商端(券商版券商端脚本机)################################################
server_ip=172.4.0.14
server_mode="
script_122_bms
script_122_ipb
script_122_irs
script_122_oms
script_122_rms
script_122_utility
script_122_pms
script_122_uds
"

for mode in ${server_mode}
do
    if [ ! -d ${base_dir}/${mode} ]; then
        mkdir ${base_dir}/${mode} -p
    fi

    beta_rsync "${server_ip}" "${user}" "${pass_file}" "${mode}" "${base_dir}/${mode}"

done

