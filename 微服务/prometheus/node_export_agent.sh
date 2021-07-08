#!/bin/bash
# linux初始化nodeport
# Author yousong.xiang
# Date 2021.7.6
# v1.0.1

node_exporter_version='1.1.2'
download_path="https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-amd64.tar.gz"
node_exporter_conf='/usr/lib/systemd/system/node_exporter.service'

function env_check {
    uid=$(id -u)
    if [ ${uid} -ne 0 ]; then
        echo '==此脚本需要root用户执行,程序即将退出.'
        exit 2
    fi

    ping -c 1 -W 2 www.aliyun.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo '==网络不通,请检查网络'
        exit 6
    fi
}

function check_rpm {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

function register_conf {
  if [ ! -f ${node_exporter_conf} ]; then
    cat>>${node_exporter_conf}<<EOF
[Unit]
Description=node_exporter

[Service]
Type=simple
Restart=on-failure
ExecStart=/usr/local/node_exporter/node_exporter --web.listen-address=0.0.0.0:9101

[Install]
WantedBy=multi-user.target
EOF
  fi
  systemctl daemon-reload
  systemctl start node_exporter.service
  systemctl enable node_exporter.service
}

function main {
  env_check
  if [ `check_rpm wget` -eq 0 ]; then
    yum install -y wget
  fi

  echo '正在下载包...'
  wget ${download_path}
  if [ $? -ne 0 ]; then
    echo '包下载失败,请检查网络！'
    exit 3
  fi
  tar -zxvf node_exporter-${node_exporter_version}.linux-amd64.tar.gz
  mv node_exporter-${node_exporter_version}.linux-amd64 /usr/local/node_exporter

  register_conf
  rm -rf node_exporter-${node_exporter_version}.linux-amd64.tar.gz
}

main
