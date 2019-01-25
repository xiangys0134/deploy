#!/bin/bash

function stop_script_server(){
    HOST_IP=$1
    HOST_PORT=$2
    HOST_USER=$3
    HOST_PASS=$4
    #sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo supervisorctl stop all"
    #if [[ $? != '0' ]];then
    #    echo "supervisor stop fail."
    #    exit 1;
    #else
    #    echo "supervisor stop Success"
    #fi
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo service cron stop"
    if [[ $? != '0' ]];then
        echo "crontab stop fail."
        exit 2;
    else
        echo "crontab stop Success"
    fi
	sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo killall php"
}

function stop_web_server(){
    HOST_IP=$1
    HOST_PORT=$2
    HOST_USER=$3
    HOST_PASS=$4
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo -H -u root bash  -c 'pm2 stop all'"
    if [[ $? != '0' ]];then
        echo "pm2 stop fail."
        exit 1;
    else
        echo "pm2 stop Success"
    fi
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo service nginx stop"
    if [[ $? != '0' ]];then
        echo "nginx stop fail."
        exit 2;
    else
        echo "nginx stop Success"
    fi
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo service php5-fpm stop"
    if [[ $? != '0' ]];then
        echo "php-fpm stop fail."
        exit 3;
    else
        echo "php-fpm stop Success"
    fi
}

function start_script_server(){
    HOST_IP=$1
    HOST_PORT=$2
    HOST_USER=$3
    HOST_PASS=$4
    #sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo supervisorctl start all"
    #[[ $? != '0' ]] && echo "supervisor start fail." ||  echo "supervisor stop Success"
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo service cron start"
    [[ $? != '0' ]] && echo "crontab start fail." ||  echo "crontab start Success"
}

function start_web_server(){
    HOST_IP=$1
    HOST_PORT=$2
    HOST_USER=$3
    HOST_PASS=$4
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo service php5-fpm start"
    [[ $? != '0' ]] && echo "php-fpm start fail." ||  echo "php-fpm start Success"
    #sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo systemctl start php7-fpm"
    #[[ $? != '0' ]] && echo "php7-fpm start fail." ||  echo "php7-fpm start Success"
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo service nginx start"
    [[ $? != '0' ]] && echo "nginx start fail." ||  echo "nginx start Success"
    sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo -H -u root bash  -c 'pm2 start all'"
    [[ $? != '0' ]] && echo "pm2 start fail." ||  echo "pm2 start Success"
}

function update_data(){
    HOST_IP=$1
    HOST_PORT=$2
    HOST_USER=$3
    HOST_PASS=$4
    release_tag=$5
    release_dir=`echo $release_tag | sed 's/\//_/g'`
    project_dir=${WORKSPACE}
    user=`sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "stat -c %U /data/www"`
    if [ -z "${user}" ]; then
        user=nginx
    fi
    group=${user}
	project_name=xc_gaoyi_edition
	project_git=ssh://git@192.168.0.38/xcadmin/xc_gaoyi_edition.git
	if [ ! -d ${project_dir} ];then
        mkdir ${project_dir}
    fi
    if [ ! -d ${project_dir}/${project_name} ];then 
        git clone ${project_git} ${project_dir}/${project_name} 
        cd ${project_dir}/${project_name} 
        git fetch --tags
        [[ $? != '0' ]] && echo "git fetch fail" && exit 1 || echo "git fetch successd"
        #[[ $? != '0' ]] && echo "git fetch fail" || echo "git fetch successd"
        git checkout ${release_tag}
        [[ $? != '0' ]] && echo "git checkout fail" && exit 2 || echo "git checkout successd"
        #[[ $? != '0' ]] && echo "git checkout fail"  || echo "git checkout successd"
    else 
        cd ${project_dir}/${project_name}
        git fetch --tags
        [[ $? != '0' ]] && echo "git fetch fail" && exit 1 || echo "git fetch successd"
        #[[ $? != '0' ]] && echo "git fetch fail"  || echo "git fetch successd"
        git checkout ${release_tag}
        [[ $? != '0' ]] && echo "git checkout fail" && exit 2 || echo "git checkout successd"
        #[[ $? != '0' ]] && echo "git checkout fail" || echo "git checkout successd"
    fi
    if [ ! -f /tmp/${release_dir}.tar.gz ];then
        cd ${project_dir}
        tar -zcf /tmp/${release_dir}.tar.gz ${project_name} --exclude=${project_name}/.git --exclude=${project_name}/xc-estimate --exclude=${project_name}/xc-estimate-front
    else
        echo "${release_dir}.tar.gz already exists"
    fi
    if [ $(sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} sudo ls /tmp/ | grep -w ${release_dir}.tar.gz | wc -l) -eq 0 ];then
        sshpass -p $HOST_PASS scp -P $HOST_PORT /tmp/${release_dir}.tar.gz ${HOST_USER}@${HOST_IP}:/tmp/
    else
        echo "Remote server ${release_dir}.tar.gz already exists"
    fi
    if [[ $? != '0' ]];then
        echo "release-tag carry fail."
        exit 1;
    else
        echo "release-tag carry Success"
    fi
    if [ $(sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} sudo ls /data/ | grep -w ${release_dir} | wc -l) -eq 0 ];then
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo tar -zxf /tmp/${release_dir}.tar.gz -C /data/"
        [[ $? != '0' ]] && echo "tar -C fail." ||  echo "tar -C Success"		
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo mv /data/${project_name} /data/${release_dir}"
        [[ $? != '0' ]] && echo "mv release_name fail." ||  echo "mv release_name Success"
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo cp -r /data/www/xc-live-tunnel/etc /data/${release_dir}/xc-live-tunnel/"
        [[ $? != '0' ]] && echo "cp live-tunnel etc fail." ||  echo "cp live-tunnel etc Success"		
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo cp -r /data/www/gmf_utility/storage/excel_parse_configs /data/${release_dir}/gmf_utility/storage/"
        [[ $? != '0' ]] && echo "cp utility_excel fail." ||  echo "cp utility_excel Success"
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo cp -r /data/www/gmf_utility/storage/app/public/* /data/${release_dir}/gmf_utility/storage/app/public/"
        [[ $? != '0' ]] && echo "cp utility_public fail." ||  echo "cp utility_public Success"
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo ln -s /data/config/rel/app/.env /data/${release_dir}/xc-pms/.env"		
        [[ $? != '0' ]] && echo "ln pms .env fail." ||  echo "ln pms .env Success"
        #sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo ln -s /data/config/rel/app/.xc_estimate_env /data/${release_dir}/xc-estimate/.env"		
        #[[ $? != '0' ]] && echo "ln xc-estimate .env fail." ||  echo "ln xc-estimate .env Success"
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo sed -i "/^user=/cuser=${user}" /data/${release_dir}/xc-pms/supervisor-worker.conf"
        [[ $? != '0' ]] && echo "supervisor_conf sed fail." ||  echo "supervisor_conf sed Success"
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo rm -f /data/www && sudo ln -s /data/${release_dir} /data/www"
        [[ $? != '0' ]] && echo "www ln fail." ||  echo "www ln Success"
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo chown -R ${user}:${group} /data/${release_dir} && sudo chown -R ${user}:${group} /data/www"
        [[ $? != '0' ]] && echo "code chown fail." ||  echo "code chown Success"
        sshpass -p $HOST_PASS ssh -p $HOST_PORT  -n ${HOST_USER}@${HOST_IP} "sudo cat /data/www/version"
    else
        echo "Sorry, existing version, please check your release-tag."
    fi		
}

if [ ! -z "$release_tag" ];then
    stop_script_server 10.31.28.50 2256 opadm 123456
    stop_web_server 10.19.253.120 2256 opadm 123456
    update_data 10.31.18.53 2256 opadm 123456 ${release_tag}
    update_data 10.91.223.22 2256 opadm 123456 ${release_tag}
    start_web_server 10.99.123.233 2256 opadm 123456
    start_script_server 10.32.58.52 2256 opadm 123456
else
    echo "release_tag input error" 
fi

