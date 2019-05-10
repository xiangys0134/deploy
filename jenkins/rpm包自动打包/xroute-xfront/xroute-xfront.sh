#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.4.25
# v1.0.1
# jenkins构建脚本

[ -f /etc/profile ] && . /etc/profile

[ -f /etc/profile ] && . /etc/profile
shell_dir=`pwd`
ftp_dir=/data/vsftpd_data/admin

function build_pkg() {
    ver="1.0.0.1"
    rm -rf ${JENKINS_HOME}/rpmbuild/RPMS/x86_64/xroute-xfront*.rpm
    cd ${JENKINS_HOME}/build
    if [[ ${select} =~ "origin" ]]; then
        ver1=`echo ${select}|awk -F '/' '{print $2}'`
        ver="${ver1}"."${BUILD_ID}"
        if [ "${ver1}" == "dev" ]; then
            tag="dev"
        else
            tag="${ver1}"
        fi
    else
        ver=`echo ${select} |awk -F "" '{for(i=2;i<=NF;i++){printf $i}}'`
        #ver=`echo ${select} |awk -F "" 'print $2$3$4$5$6$7$8$9'`
        tag="yes"
    fi
    sudo sed -i "s/^Version:.*/Version:${ver}/" xroute-xfront.spec
    /bin/cp -rf xroute-xfront.spec ${JENKINS_HOME}/rpmbuild/SPECS/
    cd ${JENKINS_HOME}/rpmbuild/SPECS/
    echo "rpmbuild start time: $(date +"%Y-%m-%d %H:%M:%S")"
    rpmbuild --bb xroute-xfront.spec
    echo "rpmbuild end time: $(date +"%Y-%m-%d %H:%M:%S")"
}

function rpm_upload() {
    if [ ! -d ${ftp_dir}/${JOB_NAME}/branch ]; then
        sudo mkdir -p ${ftp_dir}/${JOB_NAME}/branch
        if [ $? -ne 0 ]; then
            echo "FTP目录创建出错"
            exit 4
        fi
    fi

    echo "RPM upload start time: $(date +"%Y-%m-%d %H:%M:%S")"
    sudo mv -f ${JENKINS_HOME}/rpmbuild/RPMS/x86_64/${JOB_NAME}*rpm ${ftp_dir}/${JOB_NAME}/branch
    if [ $? -ne 0 ]; then
        echo "RPM包上传失败"
        exit 5
    fi
    sudo chown -R ftp. ${ftp_dir}/${JOB_NAME}
    echo "RPM upload end time: $(date +"%Y-%m-%d %H:%M:%S")"
}

build_pkg
rpm_upload

