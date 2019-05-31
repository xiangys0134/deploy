#!/bin/bash
# 资管系统推送到运维git仓库
# Date:  2019.05.29
# Version: v1.0.1



encryption_dir=${JENKINS_HOME}/workspace/xc-oms/encryption_dir


if [ ! -d ${encryption_dir} ]; then
    echo "directory not exist"
    exit 5
fi


function push_git() {
    git_url=$1
    echo "push_git start time: " `date '+%Y-%m-%d %H:%M:%S'`
    start_time=$(date +%s)
    /bin/rsync  -vzrtopgl   --delete  --exclude .git  --exclude "LICENSE"  ${encryption_dir}/ ./
    echo "$release_tag" > version
    git add .
    git commit -m "${release_tag}"
    if [ $? -ne 0 ]; then
        echo "git commit failed"
        exit 5
    fi
    stop_time=$(date +%s)
    echo "push_git End time: " `date '+%Y-%m-%d %H:%M:%S'` "Complete time: $((stop_time-start_time)) second"
    
}

push_git
