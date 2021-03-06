#!/bin/bash
source /etc/profile
set -e
############################################################################################
#                                                                                          #
# Author: xiao.li                                                                          #
# Date: 2018-08-02                                                                         #
# version:0.0.1                                                                            #
# Description: nodejs官方源同步                                                             #
# Alter:                                                                                   #
############################################################################################
function check_rpm(){
        rpm_name=$1
        num=`rpm -qa | grep ${rpm_name} |wc -l`
        echo ${num}
}
function readINI()
{
    FILENAME=$1; SECTION=$2; KEY=$3
    RESULT=`awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$KEY'/{print $2;exit}' $FILENAME`
    echo $RESULT
}

function nodejs_repo(){
cfg=$1
if [ -f ${cfg} ]; then
    rm -f ${cfg} 
fi
cat <<EOF > ${cfg}
[main]
keepcache=0

EOF

for releasever in {6..7}; do
cat << EOF >> $cfg
[nodesource-8.x-${releasever}]
name=Node.js Packages for Enterprise Linux 
baseurl=https://rpm.nodesource.com/pub_8.x/el/${releasever}/x86_64/

[nodesource-9.x-${releasever}]
name=Node.js Packages for Enterprise Linux  
baseurl=https://rpm.nodesource.com/pub_9.x/el/${releasever}/x86_64/


[nodesource-10.x-${releasever}]
name=Node.js Packages for Enterprise Linux  
baseurl=https://rpm.nodesource.com/pub_10.x/el/${releasever}/x86_64/




EOF
done


}

function repo_sync(){
	cfg=$1
	mirrors_dir=$2
    rpm_key=$3
    rpm_key_name=${rpm_key##*/}
	cache_dir="/tmp/yum-cache/"
if [ `check_rpm  yum-utils` == 0 ]; then
    yum install -y yum-utils
fi 

if [ `check_rpm  createrepo` == 0 ]; then
    yum install -y createrepo
fi
if [ ! -f ${mirrors_dir}/${rpm_key_name} ]; then
    wget -c -P ${mirrors_dir} ${rpm_key}
fi
for repoid in $(cat ${cfg} |grep -Po '(?<=\[).*(?=\])'|grep -v "main"); do
    YUM_PATH="${mirrors_dir}/$(readINI ${cfg} ${repoid} baseurl|awk -F"/" '{for(i=NF-4;i<=NF-1;i++) printf $i""FS;print ""}')"
    reposync  -c $cfg -d -p ${YUM_PATH} -e $cache_dir --repoid=${repoid}  --norepopath 
    createrepo ${YUM_PATH}/
done
}
nodejs_repo  /tmp/nodejs_repo.conf
repo_sync   /tmp/nodejs_repo.conf  /data/mirrors/nodejs-repo https://rpm.nodesource.com/pub/el/NODESOURCE-GPG-SIGNING-KEY-EL
