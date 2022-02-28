#!/bin/bash
# yousong.xiang 2022.02.28
# v1.0.2
# 切割应用nginx日志和系统日志，修改第一版出现的日志无法完整切割bug
# 传参示例：/data/scripts/stl_log_cuts_tar.sh web /data/wwwlogs /var/run/nginx.pid

[ -f /etc/profile ] && . /etc/profile

if [ $# -lt 2 ]; then
    echo $"Usage: $0 Incorrect number of parameters"
fi

function cut_log() {
    log_path=$1
    pid_path=$2
    file_type="*.log"
    file_old_time=`date -d "yesterday" +"%Y%m%d%H%M%S"`
    cd ${log_path}
    find ${log_path} -maxdepth 1 -name "${file_type}" |egrep -v "gz|[0-9]{4}[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{2}"|while read file
    do
      newfile="${file%%.log}_${file_old_time}.log"
      mv ${file} ${newfile}
    done

    if [ -n "${pid_path}" ]; then
        kill -USR1 `cat ${pid_path}`
    fi
    cd -
}

#可以作为切割系统日志,默认系统日志已经自带该功能
function cut_rsyslog() {
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

function tar_log() {
    log_path=$1
    # currTime=`date +"%Y-%m-%d"`
    file_type="*.log"
    cd "${log_path}"
    for file in `find ${log_path} -maxdepth 1 -name "${file_type}" |grep -E [0-9]{4}[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{2}[0-9]{2}|grep -v "gz"`
    do
      tar --force-local  -czf ${file}.tar.gz ${file} --remove-file
    done
    cd -
}


function dell_gz() {
    logs_path=$1
    keep_day=15
    find ${logs_path} -maxdepth 1 -name "*.tar.gz" -mtime +${keep_day} -type f -exec rm -rf {} \;
}


#系统日志,注意系统日志不需要做tar打包,tar打包默认会将所有的文件全部打包,日志会出现异常!
function man_1() {
    logs_path=$1
    pid_path=$2
    cut_rsyslog ${logs_path}
    dell_gz ${logs_path}
}

#应用日志
function man_2() {
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

