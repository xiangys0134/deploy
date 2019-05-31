#!/bin/bash
# 资管系统打包
# Date:  2019.05.29
# Version: v1.0.1


function encryption_project() {
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    start_time=$(date +%s)
    echo "encryption_project start time: ${project_name} `date '+%Y-%m-%d %H:%M:%S'` "
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    find ${project_dir}/${project_name} -name ".gitignore" -type f -exec rm -rf {} \; &>/dev/null
    /bin/rsync -vzrtopgl --delete --exclude .git --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    /usr/local/ZendGuard/bin/zendenc55 --short-tags on --delete-source --recursive --ignore-errors --ignore ${encryption_dir}/${project_name}/resources --ignore ${encryption_dir}/${project_name}/storage --ignore ${encryption_dir}/${project_name}/vendor --quiet --symlinks ${encryption_dir}/${project_name}
    if [ $? -ne 0 ]; then
        echo "zendenc55 encryption failed"
        exit 6
    fi
    stop_time=$(date +%s)
    echo "encryption_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` "Complete time: $((stop_time-start_time)) second"
}

function copy_project() {
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    start_time=$(date +%s)
    echo "copy_project start time: ${project_name} `date '+%Y-%m-%d %H:%M:%S'` "
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    find ${project_dir}/${project_name} -name ".gitignore" -type f -exec rm -rf {} \; &>/dev/null
    /bin/rsync -vzrtopgl --delete --exclude .git --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    stop_time=$(date +%s)
    echo "copy_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` "Complete time: $((stop_time-start_time)) second"
}

function php7_encryption_project() {
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    start_time=$(date +%s)
    echo "php7_encryption_project start time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'`
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    find ${project_dir}/${project_name} -name ".gitignore" -type f -exec rm -rf {} \; &>/dev/null
    /bin/rsync  -vzrtopgl   --delete  --exclude .git  --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/

    find ${encryption_dir}/${project_name} ! -path "${encryption_dir}/${project_name}/scripts" ! -path "${encryption_dir}/${project_name}/scripts/*" ! -path "${encryption_dir}/${project_name}/vendor" ! -path "${encryption_dir}/${project_name}/vendor/*" ! -path "${encryption_dir}/${project_name}/storage" ! -path "${encryption_dir}/${project_name}/storage/*" ! -path "${encryption_dir}/${project_name}/resources" ! -path "${encryption_dir}/${project_name}/resources/*" -name "*.php" -type f -exec ls -1 {} \;|while read file;
    do 
        /usr/local/php7/bin/php /data/script/encode.php ${file} ${file};
        if [ $? -ne 0 ]; then
            echo "php encode tailed"
            exit 6
        fi  
    done
    cd ${encryption_dir}/${project_name}
    /usr/local/php7/bin/php /usr/bin/php7-composer install
    if [[ $? != '0' ]];then
        echo "composer install fail"
        exit 1;
    else
        echo "composer install succeed"
    fi
    stop_time=$(date +%s)
    echo "php7_encryption_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` "Complete time: $((stop_time-start_time)) second"

}


function npm_build_project() {
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    start_time=$(date +%s)
    echo "build_project start time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'`
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    find ${project_dir}/${project_name} -name ".gitignore" -type f -exec rm -rf {} \;
    /bin/rsync  -vzrtopgl --delete --exclude .git --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    cd  ${encryption_dir}/${project_name}
    echo Begin:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`
    npm install
    if [[ $? != '0' ]];then
        echo "npm install fail"
        exit 1;
    else
        echo "npm install succeed"
    fi
    echo End:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`

    echo Begin: npm run build  `date '+%Y-%m-%d %H:%M:%S'`
    npm run build
    if [[ $? != '0' ]];then
        echo "npm build fail"
        exit 2;
    else
        echo "npm build succeed"
    fi

    echo End:npm run build  `date '+%Y-%m-%d %H:%M:%S'`
    stop_time=$(date +%s)
    echo "build_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` "Complete time: $((stop_time-start_time)) second"

}


function cnpm_build_project() {
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    start_time=$(date +%s)
    echo "build_project start time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'`
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    find ${project_dir}/${project_name} -name ".gitignore" -type f -exec rm -rf {} \;
    /bin/rsync  -vzrtopgl --delete --exclude .git --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    cd  ${encryption_dir}/${project_name}
    echo Begin:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`
    cnpm install
    if [[ $? != '0' ]];then
        echo "npm install fail"
        exit 1;
    else
        echo "npm install succeed"
    fi
    echo End:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`

    echo Begin: npm run build  `date '+%Y-%m-%d %H:%M:%S'`
    cnpm run build
    if [[ $? != '0' ]];then
        echo "npm build fail"
        exit 2;
    else
        echo "npm build succeed"
    fi

    echo End:npm run build  `date '+%Y-%m-%d %H:%M:%S'`
    stop_time=$(date +%s)
    echo "build_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` "Complete time: $((stop_time-start_time)) second"
}

function tunnel_build_project(){
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    find ${project_dir}/${project_name} -name ".gitignore" -type f -exec rm -rf {} \;

    echo "build_project start time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'`
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    /bin/rsync  -vzrtopgl   --delete  --exclude .git  --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    cd  ${encryption_dir}/${project_name}
    echo Begin:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`
    cnpm install
    if [[ $? != '0' ]];then
        echo "cnpm install fail"
        exit 1;
    else
        echo "cnpm install succeed"
    fi
    echo End:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`
    echo "build_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` 
}

function build_pkg() {
    gmf_oms=${WORKSPACE}/encryption_dir/gmf_oms
    gmf_front=${WORKSPACE}/encryption_dir/gmf_front
    xc_live_tunnel=${WORKSPACE}/encryption_dir/xc-live-tunnel

   if [ ! -d ${gmf_oms} -o ! -d ${gmf_front} -o ! -d ${xc_live_tunnel} ]; then
       echo "directory gmf_oms or gmf_front or xc-live-tunnel not exist"
       exit 5
   fi

   rm -rf ${WORKSPACE}/encryption_dir/gmf_oms/public/*
   rm -rf ${WORKSPACE}/encryption_dir/gmf_oms/resources/views/*
   rm -rf ${WORKSPACE}/encryption_dir/gmf_oms/resources/views_h5/*

   cp -rf ${WORKSPACE}/encryption_dir/gmf_front/public/*  ${WORKSPACE}/encryption_dir/gmf_oms/public/
   cp -rf ${WORKSPACE}/encryption_dir/gmf_front/resources/views/*  ${WORKSPACE}/encryption_dir/gmf_oms/resources/views/
   cp -rf ${WORKSPACE}/encryption_dir/gmf_front/resources/views_h5/*  ${WORKSPACE}/encryption_dir/gmf_oms/resources/views_h5/
   rm -rf ${WORKSPACE}/encryption_dir/xc-live-tunnel/etc
   
}

encryption_project gmf_bms
encryption_project gmf_ipb
encryption_project gmf_irs
encryption_project gmf_oms
encryption_project gmf_rms
encryption_project gmf_utility
encryption_project xc-uds
copy_project gmf_irs_front
copy_project gmf_front
php7_encryption_project xc-pms
php7_encryption_project xc-estimate
tunnel_build_project xc-live-tunnel
cnpm_build_project xc-new-front
npm_build_project xc-estimate-front
build_pkg
