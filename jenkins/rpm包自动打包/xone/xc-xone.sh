#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.4.25
# v1.0.1
# jenkins构建脚本
# rpm_check_tag--->ftp文件上传函数
# build_pkg--->rpmbuild打包函数

[ -f /etc/profile ] && . /etc/profile

shell_dir=`pwd`
ftp_dir=/data/vsftpd_data/admin
spec_file='xc-xone.spec'

function build_pkg() {
    ver='1.0.0.1'
    sudo rm -rf ${JENKINS_HOME}/rpmbuild/RPMS/x86_64/${JOB_NAME}*.rpm
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
    sudo /bin/cp -rf ${spec_file} ${JENKINS_HOME}/rpmbuild/SPECS/
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
        mkdir -p ${WORKSPACE}/${ftp_tag}
        cp -r ${JENKINS_HOME}/rpmbuild/RPMS/x86_64/${JOB_NAME}*.rpm ${WORKSPACE}/${ftp_tag}
        sudo mv -f ${JENKINS_HOME}/rpmbuild/RPMS/x86_64/${JOB_NAME}*.rpm ${ftp_dir}/XONE/${JOB_NAME}/${ftp_tag}
        if [ $? -ne 0 ]; then
          echo "RPM包上传失败"
          exit 5
        fi
        sudo chown -R ftp. ${ftp_dir}/XONE
        echo "## RPM upload end time: $(date +"%Y-%m-%d %H:%M:%S")"

}


function git_upload() {
    #ftp_tag=$1 ftp_tag取了upload_file函数内的变量，这里处理机制存在问题
    release_tag=${select}-yw
    git_url=git@192.168.0.38:ops/xc-xone-pack.git
    gir_dir=`echo ${git_url}|awk -F [/.] '{print $(NF-1)}'`
    if [[ "${release_tag}" =~ "origin" ]] || [[ "${release_tag}" =~ "xc-xone" ]]; then
        echo "The branch not need to pack"
        return 0
    fi
    cd ${WORKSPACE}
    echo "pull_git start time: " `date '+%Y-%m-%d %H:%M:%S'`
    mkdir git_tmp && cd ${WORKSPACE}/git_tmp
    git clone ${git_url}
    cd ${gir_dir}
    /bin/rsync  -vzrtopgl --delete --exclude .git ${WORKSPACE}/${ftp_tag}/ ${WORKSPACE}/git_tmp/${gir_dir}
    if [ $? -ne 0 ]; then
        echo "rsyncd filed"
        return 0
    fi

    git add --all
    git commit -m "${release_tag}"
    tag_sum=`git tag -l "${release_tag}"|wc -1`
    if [ ${tag_sum} -eq 1 ]; then
        git tag -d "${release_tag}"
        git push origin -d "${release_tag}"
    fi

    git tag -a -f -m "" "$release_tag"
    [[ $? != '0' ]] && echo "git add tag $release_tag fail" && return 0 || echo "git add tag $release_tag successd"
    git push ${git_url}  "$release_tag" -f
    [[ $? != '0' ]] && echo "git push tag failed" && return 0 || echo "git push tag successd"
    echo "pull_git End time: " `date '+%Y-%m-%d %H:%M:%S'`

}


function rpm_check_tag() {
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
        #mv ${JOB_NAME}-${ver}.tar.gz ${ftp_dir}/XONE/${JOB_NAME}/brach
        upload_file brach
    fi

}

build_pkg
rpm_check_tag
git_upload

