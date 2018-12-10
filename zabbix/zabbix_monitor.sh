#!/bin/bash
#zabbix agent告警

[ -f /etc/profile ] && . /etc/profile

if [ $# -ne 1 ]; then
    echo "USAGE: $0 args[1]"
fi

function crontab_agent() {
    crontab_active=`systemctl status crond.service |grep "active (running)"|wc -l`
    if [ "${crontab_active}" == "1" ]; then
        return 0
    else
        return 1
    fi

}

case $1 in
crontab_check)
    crontab_agent
    REVELT=$?
    echo ${REVELT}
    ;;
*)
    echo "USAGE: $0 'crontab_check'"
    ;;
esac
