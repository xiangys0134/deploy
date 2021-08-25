#!/bin/bash
# 功能:检测证书过期天数
# yousong.xiang
# 2021.8.25
# v1.0.1
# 域名存储文件domain_ssl.info,同时脚本所在的服务器需要安装openssl,同时要保证域名及端口能通

[ -f /etc/profile ] && . /etc/profile

script_dir=`cd "$( dirname "$0"  )" && pwd`
domain_file="domain_ssl.info"
check_log=${script_dir}/check_domain.log
dingtalk="https://oapi.dingtalk.com/robot/send?access_token=90fea408c219b11aa93ae518ad38460074077737992144dcfb86b65f08093b96"

if [ ! -f ${script_dir}/${domain_file} ]; then
  touch ${script_dir}/${domain_file}
fi

egrep -v "^#|^$" ${script_dir}/${domain_file} |while read line
do
  get_domain=`echo "${line}" | awk -F ':' '{print $1}'`
  get_port=`echo "${line}" | awk -F ':' '{print $2}'`
  END_TIME=`echo | openssl s_client -servername ${get_domain}  -connect ${get_domain}:${get_port} 2>/dev/null | openssl x509 -noout -dates |grep 'After'| awk -F '=' '{print $2}'| awk -F ' +' '{print $1,$2,$4 }'`
  t_time=`date '+%Y-%m-%d %H:%M:%S'`
  if [ $? -ne 0 ] || [ -z "${END_TIME}" ]; then
    echo "${t_time} ${get_domain}证书检测失败!" >> ${check_log}
  else
    echo "${t_time} ${get_domain}证书检测中..." >> ${check_log}
  fi
  sleep 1;
  END_TIME1=`date +%s -d "$END_TIME"`

  #将目前的日期也转化为时间戳
  NOW_TIME=`date +%s -d "$(date | awk -F ' +'  '{print $2,$3,$6}')"`

  #到期时间减去目前时间再转化为天数
  RST=$(($(($END_TIME1-$NOW_TIME))/(60*60*24)))

  t_time=`date '+%Y-%m-%d %H:%M:%S'`
  echo "${t_time} ${get_domain}有效期：${RST}" >> ${check_log}

  # 如果小于10天则进行告警推送
  if [ $RST -lt 10 ]; then
    echo "证书${get_domain}有效期小于10天!"
    curl ${dingtalk} \
-H 'Content-Type: application/json' \
-d '
{
	"msgtype": "text",
	"text": {
	  "content": "warning 证书'${get_domain}'有效期小于10天或端口证书检测异常!"
	}
}'
  else
    echo "证书${get_domain}有效期大于等于10天"
  fi
done

