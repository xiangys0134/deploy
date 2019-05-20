#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.4.25
# v1.0.1
# jenkins构建脚本

[ -f /etc/profile ] && . /etc/profile
shell_dir=`pwd`
ftp_dir=/data/vsftpd_data/admin
spec_file='xroute-xfront.spec'

function build_pkg() {
    ver="1.0.0.1"
    sudo rm -rf ${JENKINS_HOME}/rpmbuild/RPMS/x86_64/xroute-xfront*.rpm
    sudo rm -rf ${JENKINS_HOME}/rpmbuild/BUILD/${JOB_NAME}
    cp -rf ${JENKINS_HOME}/workspace/${JOB_NAME} ${JENKINS_HOME}/rpmbuild/BUILD/

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
    sudo sed -i "s/^Version:.*/Version:${ver}/" ${spec_file}
    /bin/cp -rf ${spec_file} ${JENKINS_HOME}/rpmbuild/SPECS/
    cd ${JENKINS_HOME}/rpmbuild/SPECS/
    echo "## rpmbuild start time: $(date +"%Y-%m-%d %H:%M:%S")"
    rpmbuild --bb ${spec_file}
    if [ $? -ne 0 ]; then
         echo "rpmbuild failed"
         exit 5
    fi
    echo "## rpmbuild end time: $(date +"%Y-%m-%d %H:%M:%S")"
}


function upload_file() {
        ftp_tag=$1
        echo "## RPM upload start time: $(date +"%Y-%m-%d %H:%M:%S")"
        echo "${JENKINS_HOME}/rpmbuild/RPMS/x86_64"
        ls ${JENKINS_HOME}/rpmbuild/RPMS/x86_64
        echo "${ftp_dir}/${JOB_NAME}"
        echo "${JENKINS_HOME}/rpmbuild/RPMS/x86_64/${JOB_NAME}*rpm"
        sudo mv -f ${JENKINS_HOME}/rpmbuild/RPMS/x86_64/${JOB_NAME}*.rpm ${ftp_dir}/${JOB_NAME}/${ftp_tag}
        if [ $? -ne 0 ]; then
          echo "RPM包上传失败"
          exit 5
        fi
        sudo chown -R ftp. ${ftp_dir}
        echo "## RPM upload end time: $(date +"%Y-%m-%d %H:%M:%S")"

}

function rpm_check_tag() {
    if [ "${tag}" == "dev" ]; then
        if [ ! -d ${ftp_dir}/${JOB_NAME}/dev ]; then
            sudo mkdir -p ${ftp_dir}/${JOB_NAME}/dev
        fi
        upload_file dev
    elif [ "${tag}" == "yes" ]; then
        if [ ! -d ${ftp_dir}/${JOB_NAME}/tag ]; then
            sudo mkdir -p ${ftp_dir}/${JOB_NAME}/tag
        fi
        upload_file tag
    else
        if [ ! -d ${ftp_dir}/${JOB_NAME}/brach ]; then
            sudo mkdir -p ${ftp_dir}/${JOB_NAME}/brach
        fi
        #mv ${JOB_NAME}-${ver}.tar.gz ${ftp_dir}/${JOB_NAME}/brach
        upload_file brach
    fi
}


build_pkg
rpm_check_tag
