#!/bin/bash
source /etc/profile
set -e
############################################################################################
#                                                                                          #
# Author: xiao.li                                                                          #
# Date: 2018-08-02                                                                         #
# version:0.0.1                                                                            #
# Description: Webtatic官方源同步                                                          #
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

function webtatic_repo(){
cfg=$1
if [ -f ${cfg} ]; then
    rm -f ${cfg} 
fi
cat <<EOF > ${cfg}
[main]
keepcache=0

EOF

for releasever in {6..7}; do
    for basearch in {x86_64,SRPMS}; do
cat << EOF >> $cfg
[webtatic-${releasever}-${basearch}]
name=Webtatic Repository EL7 - $basearch
baseurl=http://repo.webtatic.com/yum/el$releasever/$basearch/

[webtatic-source${releasever}-${basearch}]
name=Webtatic Repository EL7 - $basearch - Source
baseurl=http://repo.webtatic.com/yum/el$releasever/SRPMS/



EOF
    done
done


}

function repo_sync(){
	cfg=$1
	mirrors_dir=$2
	cache_dir="/tmp/yum-cache/"
if [ `check_rpm  yum-utils` == 0 ]; then
    yum install -y yum-utils
fi 

if [ `check_rpm  createrepo` == 0 ]; then
    yum install -y createrepo
fi
if [ ! -f ${mirrors_dir}/RPM-GPG-KEY-webtatic-el7 ]; then
    wget -c -P ${mirrors_dir} http://repo.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7
fi
if [ ! -f ${mirrors_dir}/RPM-GPG-KEY-webtatic-el6 ]; then
    wget -c -P ${mirrors_dir} http://repo.webtatic.com/yum/RPM-GPG-KEY-webtatic-el6
fi
for repoid in $(cat ${cfg} |grep -Po '(?<=\[).*(?=\])'|grep -v "main"); do
    YUM_PATH="${mirrors_dir}/$(readINI ${cfg} ${repoid} baseurl|awk -F"/" '{for(i=NF-3;i<=NF-1;i++) printf $i""FS;print ""}')"
    reposync  -c $cfg -d -p ${YUM_PATH} -e $cache_dir --repoid=${repoid}  --norepopath 
    createrepo ${YUM_PATH}/
done
}
webtatic_repo  /tmp/webtatic_repo.conf
repo_sync   /tmp/webtatic_repo.conf  /data/mirrors/webtatic 
