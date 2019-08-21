#!/bin/bash
source /etc/profile
set -e
############################################################################################
#                                                                                          #
# Author: xiao.li                                                                          #
# Date: 2018-08-02                                                                         #
# version:0.0.1                                                                            #
# Description: mysql官方源同步                                                             #
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

function mysql_repo(){
cfg=$1
if [ -f ${cfg} ]; then
    rm -f ${cfg} 
fi
cat <<EOF > ${cfg}
[main]
keepcache=0

EOF

for releasever in {6..7}; do
    for basearch in {i386,x86_64,SRPMS}; do
cat << EOF >> $cfg
[mysql-connectors-community-${releasever}-${basearch}]
name=MySQL Connectors Community
baseurl=http://repo.mysql.com/yum/mysql-connectors-community/el/$releasever/$basearch/
enabled=1


[mysql-tools-community-${releasever}-${basearch}]
name=MySQL Tools Community
baseurl=http://repo.mysql.com/yum/mysql-tools-community/el/$releasever/$basearch/
enabled=1


[mysql-cluster-75-community-${releasever}-${basearch}]
name=MySQL Cluster 7.5 Community
baseurl=http://repo.mysql.com/yum/mysql-cluster-7.5-community/el/$releasever/$basearch/
enabled=1


[mysql-cluster-76-community-${releasever}-${basearch}]
name=MySQL Cluster 7.6 Community
baseurl=http://repo.mysql.com/yum/mysql-cluster-7.6-community/el/$releasever/$basearch/
enabled=1


# Enable to use MySQL 5.5
[mysql55-community-${releasever}-${basearch}]
name=MySQL 5.5 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.5-community/el/$releasever/$basearch/
enabled=1


# Enable to use MySQL 5.6
[mysql56-community-${releasever}-${basearch}]
name=MySQL 5.6 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/$releasever/$basearch/
enabled=1


[mysql57-community-${releasever}-${basearch}]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/$releasever/$basearch/
enabled=1

[mysql80-community-${releasever}-${basearch}]
name=MySQL 8.0 Community Server
baseurl=http://repo.mysql.com/yum/mysql-8.0-community/el/$releasever/$basearch/
enabled=1


EOF
    done
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
mysql_repo  /tmp/mysql_repo.conf
repo_sync   /tmp/mysql_repo.conf  /data/mirrors/mysql-repo/yum http://repo.mysql.com/RPM-GPG-KEY-mysql
