#!/bin/bash
function Environmental_monitoring(){
    pingres=`ping -c 1 baidu.com | sed -n '/64 bytes from/p'`
    if [ -z "$pingres" ];then
        echo "network error" 
        exit 1;
    else
        echo "network right"
    fi
    if [ "`ls -A ${WORKSPACE}`" = "" ]; then
        echo "${WORKSPACE} does not exist,Right!"
    else
        echo "${WORKSPACE} exist,Error!"
        exit 1;
    fi
}

function sub_project() {
    release_tag=$1
    project_name=$2
    project_git=$3
    project_dir=${WORKSPACE}/project_dir
    echo "sub_project start time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` 
    if [ ! -d ${project_dir} ];then
        mkdir ${project_dir}
    fi
    if [ ! -d ${project_dir}/${project_name} ];then 
        git clone ${project_git} ${project_dir}/${project_name} 
        [[ $? != '0' ]] && echo "git clone ${project_name} fail" && exit 1 || echo "git clone ${project_name} successd"
        cd ${project_dir}/${project_name} 
        git pull
        [[ $? != '0' ]] && echo "git pull ${project_name} fail" && exit 2 || echo "git pull ${project_name} successd"
        git checkout master
        [[ $? != '0' ]] && echo "git checkout ${project_name} fail" && exit 3 || echo "git checkout ${project_name} successd"  
        rm -f ${project_dir}/${project_name}/.gitignore
        git tag -l "${release_tag}"
        git tag -a -f -m "$bms_message" "${release_tag}"
        git --version
        git push ${project_git} "${release_tag}" -f
        [[ $? != '0' ]] && echo "git push ${project_name} fail" && exit 4 || echo "git push ${project_name} successd"
    else 
        cd ${project_dir}/${project_name}
        git pull
        [[ $? != '0' ]] && echo "git pull ${project_name} fail" && exit 1 || echo "git pull ${project_name} successd"
        git checkout master
        [[ $? != '0' ]] && echo "git checkout ${project_name} fail" && exit 2 || echo "git checkout ${project_name} successd"        
        rm -f ${project_dir}/${project_name}/.gitignore
        git tag -l "${release_tag}"
        git tag -a -f -m "$bms_message" "${release_tag}"
        git --version
        git push ${project_git} "${release_tag}" -f
        [[ $? != '0' ]] && echo "git push ${project_name} fail" && exit 3 || echo "git push ${project_name} successd"
    fi
    echo "sub_project End time: ${project_name} " `date '+%Y-%m-%d %H:%M:%S'`
}
function encryption_project(){
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    echo "encryption_project start time: ${project_name} `date '+%Y-%m-%d %H:%M:%S'` "
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    /bin/rsync  -vzrtopgl   --delete  --exclude .git  --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    /usr/local/ZendGuard/bin/zendenc55  --short-tags on --delete-source --recursive --ignore-errors   --ignore ${encryption_dir}/${project_name}/resources  --ignore ${encryption_dir}/${project_name}/storage --ignore ${encryption_dir}/${project_name}/vendor   --quiet   --symlinks   ${encryption_dir}/${project_name}
    echo "encryption_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` 
}

function php7_encryption_project(){
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    echo "php7_encryption_project start time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'`
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    /bin/rsync  -vzrtopgl   --delete  --exclude .git  --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    find ${encryption_dir}/${project_name} ! -path "${encryption_dir}/${project_name}/scripts" ! -path "${encryption_dir}/${project_name}/scripts/*" ! -path "${encryption_dir}/${project_name}/vendor" ! -path "${encryption_dir}/${project_name}/vendor/*" ! -path "${encryption_dir}/${project_name}/storage" ! -path "${encryption_dir}/${project_name}/storage/*" ! -path "${encryption_dir}/${project_name}/resources" ! -path "${encryption_dir}/${project_name}/resources/*" -name "*.php" -type f -exec ls -1 {} \;|while read file;
    do 
      /usr/local/php7/bin/php /data/script/encode.php ${file} ${file}; 
    done
    cd ${encryption_dir}/${project_name}
    /usr/local/php7/bin/php /usr/bin/php7-composer install
    if [[ $? != '0' ]];then
        echo "composer install fail"
        exit 1;
    else
        echo "composer install succeed"
    fi
    echo "php7_encryption_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'`
}

function build_project(){
    project_name=$1
    project_dir=${WORKSPACE}/project_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    echo "build_project start time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'`
    if [ ! -d ${encryption_dir} ];then
        mkdir ${encryption_dir}
    fi
    rm -fr ${encryption_dir}/${project_name}
    /bin/rsync  -vzrtopgl   --delete  --exclude .git  --exclude "LICENSE"  ${project_dir}/${project_name} ${encryption_dir}/
    cd  ${encryption_dir}/${project_name}
    rm -f .gitignore
    echo Begin:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`
    cnpm install
    if [[ $? != '0' ]];then
        echo "cnpm install fail"
        exit 1;
    else
        echo "cnpm install succeed"
    fi
    echo End:cnpm install   `date '+%Y-%m-%d %H:%M:%S'`
    echo Begin: npm run build  `date '+%Y-%m-%d %H:%M:%S'`
    npm run build
    echo End:npm run build  `date '+%Y-%m-%d %H:%M:%S'`
    echo "build_project End time: ${project_name}" `date '+%Y-%m-%d %H:%M:%S'` 
}

function pull_git(){
    ops_tag=$1
    git_dir=${WORKSPACE}/git_dir
    encryption_dir=${WORKSPACE}/encryption_dir
    echo "pull_git start time: " `date '+%Y-%m-%d %H:%M:%S'`
    if [ ! -d ${git_dir} ];then
        git clone ssh://git@10.0.0.42/code/tg_rel_compile_pack.git ${git_dir}
        [[ $? != '0' ]] && echo "git clone tg_rel_compile_pack fail" && exit 1 || echo "git clone xc_rel_compile_pack successd"
    else
        cd ${git_dir}
        git pull
        [[ $? != '0' ]] && echo "git pull tg_rel_compile_pack fail" && exit 1 || echo "git pull xc_rel_compile_pack successd"
        git checkout master
        [[ $? != '0' ]] && echo "git checkout tg_rel_compile_pack fail" && exit 2 || echo "git checkout xc_rel_compile_pack successd"
    fi
    cd ${git_dir}
    /bin/rsync  -vzrtopgl   --delete  --exclude .git ${encryption_dir}/  ${git_dir}
    rm -rf ${git_dir}/ctx_oms/public/*
    rm -rf ${git_dir}/ctx_oms/resources/views/*
    rm -rf ${git_dir}/ctx_oms/resources/views_h5/*

    cp -rf ${git_dir}/ctx_front/public/*  ${git_dir}/ctx_oms/public/
    cp -rf ${git_dir}/ctx_front/resources/views/*  ${git_dir}/ctx_oms/resources/views/
    cp -rf ${git_dir}/ctx_front/resources/views_h5/*  ${git_dir}/ctx_oms/resources/views_h5/
    rm -fr ${git_dir}/gr-live-tunnel/etc 
    echo ctx_front/ >.gitignore
    cd ${git_dir}
    echo "$release_tag" > version
    echo "$subsystem" | tr "," "\n" >> version
    git add .
    git commit -m "$release_tag"
    git tag -l "$release_tag"
    git tag -a -f -m "" "$release_tag"
    [[ $? != '0' ]] && echo "git add tag $release_tag fail" && exit 3 || echo "git add tag $release_tag successd"
    git push ssh://git@10.0.0.42/code/tg_rel_compile_pack.git  "$release_tag" -f
    [[ $? != '0' ]] && echo "git push tg_rel_compile_pack fail" && exit 4 || echo "git push xc_rel_compile_pack successd"
    echo "pull_git End time: " `date '+%Y-%m-%d %H:%M:%S'`
}


if [ ! -z "$release_tag" ];then
    Environmental_monitoring
    rm -f /tmp/php_beast.log
    sub_project  ${release_tag} ctx_bms ssh://git@10.0.0.24:11022/test/ctx_bms.git     
    sub_project  ${release_tag} ctx_oms ssh://git@10.0.0.24:11022/test/ctx_oms_v2.git      
    sub_project  ${release_tag} ctx_rms ssh://git@10.0.0.24:11022/backend/ctx_rms.git      
    sub_project  ${release_tag} ctx_irs ssh://git@10.0.0.24:11022/test/gr-irs.git     
    sub_project  ${release_tag} ctx_irs_front ssh://git@10.0.0.24:11022/test/irs-front.git      
    sub_project  ${release_tag} ctx_utility ssh://git@10.0.0.24:11022/test/-utility.git      
    sub_project  ${release_tag} uds ssh://git@10.0.0.24:11022/test/gr-uds.git      
    sub_project  ${release_tag} live-tunnel ssh://git@10.0.0.24:11022/test/live-tunnel.git      
    sub_project  ${release_tag} ctx_ipb ssh://git@10.0.0.24:11022/test/ctx_ipb.git     
    sub_project  ${release_tag} pms ssh://git@10.0.0.24:11022/test/gr-pms.git     
    sub_project  ${release_tag} ctx_front ssh://git@10.0.0.24:11022/test/xcfrontend.git
    sub_project  ${release_tag} gr-estimate ssh://git@10.0.0.24:11022/test/xc-estimate.git
    sub_project  ${release_tag} gr-estimate-front ssh://git@10.0.0.24:11022/test/xc-estimate-front.git
    encryption_project ctx_bms
    encryption_project ctx_rms
    encryption_project ctx_oms
    encryption_project ctx_irs
    encryption_project ctx_irs_front
    encryption_project ctx_utility
    encryption_project gr-uds 
    encryption_project ctx_ipb 
    php7_encryption_project gr-pms
    php7_encryption_project gr-estimate
    build_project gr-live-tunnel
    build_project ctx_front
    build_project gr-estimate-front
    pull_git ${release_tag}
else
    echo "release_tag does not exist" 
fi
    


