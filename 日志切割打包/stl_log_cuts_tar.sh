#!/bin/bash
#Yusin 2021.04.23
#v1.0.1
#
# 切割应用程序日志和系统日志
# bash -x stl_log_cuts_tar.sh web /data/wwwlogs /var/run/nginx.pid

[ -f /etc/profile ] && . /etc/profile
if [ $# -lt 2 ]; then
    echo $"Usage: $0 Incorrect number of parameters"
fi 


cmd=`pwd`

cut_log() {
    log_path=$1
    pid_path=$2
    file_type="*.log"
    for file in `find ${log_path} -maxdepth 1 -name ${file_type} |egrep -v "[0-9]{4}-[0-9]{2}-[0-9]{2}|gz$|_[0-9]{4}[0-9]{2}[0-9]{2}[0-9]{2}"`
    do
        mv ${file} "${file%%.log}_`date -d "yesterday" +"%Y%m%d%H%M%S"`.log"
    done 

    if [ -n "${pid_path}" ]; then
        kill -USR1 `cat ${pid_path}`
    fi

}

#可以作为切割系统日志,默认系统日志已经自带该功能
cut_rsyslog() {
    log_path=$1
    if [ -d "${log_path}" ]; then
        for file in "`find ${log_path} -type f|egrep "messages|secure|maillog|cron"`"
        do
            if [ `echo "${file}" |grep "-"|wc -l` -ge 1 ]; then
                #删除大于15天的系统日志
                [ `find ${file} -maxdepth 1 -mtime +15` ] && rm -rf ${file}
                continue
            fi 
            mv ${file} ${file}-`date -d "yesterday" +"%Y%m%d%H%M"`
            /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
        done
    fi
    
}

tar_log() {
    log_path=$1
    currTime=`date +"%Y-%m-%d"`
    curr_log_file=`ls "${log_path}"|egrep -v "gz$"`
    if [ "${curr_log_file}" != '' ]; then
        new_arr=("${curr_log_file}")
        echo ${new_arr}
        cd "${log_path}"
        for file in ${new_arr[@]}
        do  
            #echo ${file}"############"
            time_stamp=`stat -c %Y  ${file}`
            [ $? -eq 0 ] && time_stamp=`date -d @${time_stamp} "+%Y-%m-%d"`
            #echo `date`
            #time_stamp=`date -d @${time_stamp} "+%Y-%m-%d"`
            #if [ `date -d "@${time_stamp}" "+%Y-%m-%d"` == "${currTime}" ]; then
            if [ "${time_stamp}" == "${currTime}" ]; then
                echo "${file}"
                continue
            fi
            #echo "${file}"
            tar --force-local  -czf ${file}.tar.gz ${file} --remove-file
        done
        cd ${cmd}
    fi
    
}


dell_gz() {
    logs_path=$1 
    keep_day=15
    find ${logs_path} -maxdepth 1 -name "*.tar.gz" -mtime +${keep_day} -type f -exec rm -rf {} \;
}


#系统日志,注意系统日志不需要做tar打包,tar打包默认会将所有的文件全部打包,日志会出现异常!
man_1() {
    logs_path=$1
    pid_path=$2
    cut_rsyslog ${logs_path}
    dell_gz ${logs_path}
}

#应用日志
man_2() {
    logs_path=$1
    pid_path=$2
    cut_log ${logs_path} ${pid_path}
    tar_log ${logs_path}
    dell_gz ${logs_path}
}


case $1 in
  sys)
    shift
    man_1 $*
    ;;
  web)
    shift
    man_2 $* 
    ;;
  *)
    echo $"Usage: $0 '$1:{web|sys}'"
    exit 5     
esac

