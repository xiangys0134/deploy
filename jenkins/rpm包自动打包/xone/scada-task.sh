#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.16
# v1.0.2
# jenkins构建脚本

[ -f /etc/profile ] && . /etc/profile
ftp_dir=/data/vsftpd_data/admin
ftp_host='192.168.5.205'
select=${select}

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
        ver=${select##v} 
    fi
    #cd ${WORKSPACE}
    echo ""
    echo "## maven build start time: $(date +"%Y-%m-%d %H:%M:%S")"
    echo ""
    mvn clean compile verify -P prod -Dmaven.test.skip=true
    if [ $? -ne 0 ]; then
        echo "mvn buld failed!"
        exit 4
    fi
    echo ""
    echo "## maven build stop time: $(date +"%Y-%m-%d %H:%M:%S")"
    echo ""
    [ -f version ] && cp version ${WORKSPACE}/target/${JOB_NAME}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/${JOB_NAME}/
    cd ${WORKSPACE}/target/${JOB_NAME}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/
    mv ${JOB_NAME} ${JOB_NAME}-${ver}
    tar -czf ${JOB_NAME}-${ver}.tar.gz ${JOB_NAME}-${ver} 
}


function upload_file() {
        ftp_tag=$1
        echo "## RPM upload start time: $(date +"%Y-%m-%d %H:%M:%S")"

        cd ${WORKSPACE}/target/${JOB_NAME}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/
    
        mkdir -p ${WORKSPACE}/${ftp_tag}
        cp -r ${JOB_NAME}-${ver}.tar.gz ${WORKSPACE}/${ftp_tag}
        sudo mv -f ${JOB_NAME}-${ver}.tar.gz ${ftp_dir}/XONE/${JOB_NAME}/${ftp_tag}
        if [ $? -eq 0 ]; then
            echo "upload file success"
            echo "ftp://${ftp_host}/XONE/${JOB_NAME}/${ftp_tag}/${JOB_NAME}-${ver}.tar.gz"
        else
            echo "upload file failed"
            exit 5
        fi

        echo "## RPM upload end time: $(date +"%Y-%m-%d %H:%M:%S")"

}

function backup_scadatask() {
    if [ "${tag}" == "dev" ]; then
        if [ ! -d ${ftp_dir}/XONE/${JOB_NAME}/dev ]; then
            sudo mkdir -p ${ftp_dir}/XONE/${JOB_NAME}/dev
        fi
        upload_file dev
    elif [ "${tag}" == "yes" ]; then
        if [ ! -d ${ftp_dir}/XONE/${JOB_NAME}/tag ]; then
            sudo mkdir -p ${ftp_dir}/XONE/${JOB_NAME}/tag
        fi
        upload_file tag
    else
        if [ ! -d ${ftp_dir}/XONE/${JOB_NAME}/brach ]; then
            sudo mkdir -p ${ftp_dir}/XONE/${JOB_NAME}/brach
        fi
        upload_file brach
    fi

}


build_scadatask
backup_scadatask
