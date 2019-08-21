#!/bin/bash
source /etc/profile
set -e
############################################################################################
#                                                                                          #
# Author: xiao.li                                                                          #
# Date: 2018-08-02                                                                         #
# version:0.0.1                                                                            #
# Description: rsync镜像仓库步                                                             #
# Alter:                                                                                   #
############################################################################################
function check_rpm(){
        rpm_name=$1
        num=`rpm -qa | grep ${rpm_name} |wc -l`
        echo ${num}
}
function rsync_epel(){
mirrors_dir=$1
UPSTREAM=rsync://dl.fedoraproject.org
REPOS=("fedora-epel" "")
RSYNC_OPTS="-aHvh --no-o --no-g --stats --exclude .~tmp~/ --delete --delete-after --delay-updates --safe-links --timeout=120 --contimeout=120"
USE_IPV6=${USE_IPV6:-"0"}
if [[ $USE_IPV6 == "1" ]]; then
        RSYNC_OPTS="-6 ${RSYNC_OPTS}"
fi

if [ `check_rpm  rsync` == 0 ]; then
    yum install -y rsync
fi
for repo in ${REPOS[@]}; do
        upstream=${UPSTREAM}/${repo}
        dest=${mirrors_dir}/${repo}

        [ ! -d "$dest" ] && mkdir -p "$dest"

        rsync ${RSYNC_OPTS} "$upstream" "$dest"
done
 
}
rsync_epel /data/mirrors

