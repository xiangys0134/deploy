#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.10
# v1.0.1
# jenkins构建脚本

[ -f /etc/profile ] && . /etc/profile
ftp_dir=/data/vsftpd_data/admin

function build_scadatask() {    
    ver='1.0.0'
    if [[ $select =~ "origin" ]]; then
        ver1=`echo ${select}|awk -F '/' '{print $2}'`
        ver=${ver1}.${BUILD_ID}
        if [ "${ver1}" == "dev" ]; then
            tag="dev"
        else
            tag="${ver1}"
        fi
    else
        tag="yes"
        ver=`echo ${select} |awk -F "" '{for(i=2;i<=NF;i++){printf $i}}'`        
    fi
    cd ${WORKSPACE}
    mvn clean compile verify -P prod -Dmaven.test.skip=true
    if [ $? -ne 0 ]; then
        echo "mvn buld failed!"
        exit 4
    fi
    cd ${WORKSPACE}/target/${JOB_NAME}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/
    mv ${JOB_NAME} ${JOB_NAME}-${ver}
    tar -czf ${JOB_NAME}-${ver}.tar.gz ${JOB_NAME}-${ver} 
}

function backup_scadatask() {
    if [ "${tag}" == "dev" ]; then
        if [ ! -d ${ftp_dir}/XONE/${JOB_NAME}/dev ]; then
            mkdir -p ${ftp_dir}/XONE/${JOB_NAME}/dev
        fi
        cd ${WORKSPACE}/target/${JOB_NAME}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/
        mv ${JOB_NAME}-${ver}.tar.gz ${ftp_dir}/XONE/${JOB_NAME}/dev
    elif [ "${tag}" == "yes" ]; then
        if [ -d ${ftp_dir}/XONE/${JOB_NAME}/tag ]; then
            mkdir -p ${ftp_dir}/XONE/${JOB_NAME}/tag
        fi
        cd ${WORKSPACE}/target/${JOB_NAME}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/
        mv ${JOB_NAME}-${ver}.tar.gz ${ftp_dir}/XONE/${JOB_NAME}/tag
    else
        if [ ! -d ${ftp_dir}/XONE/${JOB_NAME}/brach ]; then
            mkdir ${ftp_dir}/XONE/${JOB_NAME}/brach
        fi
        cd ${WORKSPACE}/target/${JOB_NAME}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/
        mv ${JOB_NAME}-${ver}.tar.gz ${ftp_dir}/XONE/${JOB_NAME}/brach
    fi
}

build_scadatask
backup_scadatask
