#!/bin/bash
# Nginx1.14.2 源码包安装
# Author yousong.xiang 250919938@qq.com
# Date 2019.03.06
# v1.0.1

[ -f /etc/profile ] && . /etc/profile
cmd=`dirname $0`
#nginx编译安装路径,可自行修改
BASEDIR=/usr/local/nginx

if [ "${cmd}" == '.' ]; then
    cmd=`pwd`
fi

#检查网络状态
function env_check() {
    uid=$(id -u)
    if [ ${uid} -ne 0 ]; then
        echo '==此脚本需要root用户执行,程序即将退出.'
        exit 2        
    fi

    ping -c 1 -W 2 www.baidu.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo '==网络不通,请检查网络'
        exit 6
    fi 
}

#检查rpm包是否安装
function check_rpm() {
    rpm_pkg=$1
    num=`rpm -qa|grep ${rpm_pkg}|wc -l`
    echo ${num}
}

#关闭selinux
function selinux_stop(){
    sed -i '/^SELINUX=enforcing$/c\SELINUX=disabled' /etc/selinux/config
    setenforce 0
}


function rpm_install(){
    num=`env_check epel-release`
    if [ "${num}" == "0" ]; then
        echo "epel-release install ..."
        yum install -y epel-release &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "\033[32mInstall epel-release seccess\033[0m"
        else
            echo -e "\033[31mInstall epel-release failure\033[0m"
        fi
    fi
    yum install -y gcc gcc-c++ pcre-devel openssl-devel patch make unzip
}

function code_install() {
    if [ -f /var/log/nginx_code.lock ]; then
        echo -e "\033[31mnginx已经安装,请确认\033[0m"
        exit 3
    fi
    cd ${cmd}
    if [ -f master.zip ]; then
        rm -rf master.zip
        if [ -d nginx_upstream_check_module-master ]; then
            rm -rf nginx_upstream_check_module-master
        fi
    fi

    wget https://github.com/yaoweibin/nginx_upstream_check_module/archive/master.zip
    if [ $? -ne 0 ]; then
        echo -e "\033[31mWget make fail\033[0m"
        exit 6    
    fi

    id www &>/dev/null
    if [ $? -ne 0 ]; then
        groupadd www && useradd -M -g www -s /sbin/nologin www
    fi

    if [ -d nginx-1.14.2 ]; then
        rm -rf nginx-1.14.2
    fi
    if [ ! -f nginx-1.14.2.tar.gz ]; then
        wget http://soft.g6p.cn/deploy/source/nginx-1.14.2.tar.gz &>/dev/null
    
        if [ $? -ne 0 ]; then
            echo -e "\033[31mWget nginx-1.14.2.tar.gz fail\033[0m"
            exit 7
        fi
    fi

    unzip master.zip &>/dev/null
    tar zxf nginx-1.14.2.tar.gz && cd nginx-1.14.2
    echo "start..."
    patch -p1 < ../nginx_upstream_check_module-master/check_1.14.0+.patch 
    echo "end..."
    if [ $? -ne 0 ]; then    
        echo -e "\033[31mImport patch fail\033[0m"
        exit 8
    fi

    ./configure \
--user=www \
--group=www \
--prefix=${BASEDIR} \
--with-http_stub_status_module \
--with-pcre \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_gzip_static_module \
--with-http_realip_module \
--add-module=../nginx_upstream_check_module-master \
--with-ipv6

   if [ $? -ne 0 ]; then
       echo -e "\033[31mNginx configure fail\033[0m"
       exit 9
   fi
   make
   if [ $? -ne 0 ]; then
       echo -e "\033[31mNginx make fail\033[0m"
       exit 1
   fi
   make install 
   if [ $? -ne 0 ]; then
       echo -e "\033[31mNginx make install fail\033[0m"
       exit 1
   else
       touch /var/log/nginx_code.lock
   fi

}

function nginx_config() {
    BACKTIME=`date '+%Y%m%d%H%M'`
    proxy_java_conf=${BASEDIR}/conf/proxy_java.conf
    #nginx_upstream_conf=${BASEDIR}/conf/vhost/upstream.conf
    localhost_conf=${BASEDIR}/conf/vhost/localhost.conf
    nginx_service=/lib/systemd/system/nginx.service

    if [ ! -f /var/log/env.profile ]; then
        echo "export PATH=$PATH:${BASEDIR}/sbin" >> /etc/profile
        touch /var/log/env.profile
    fi

    #日志目录存放路径,站点存放路径(目录为软连接),源码存放路径，java和前端源码都存放在这个目录下
    mkdir /data/logs -p && mkdir /data/www && mkdir /data/code
    chown -R www. /data/logs /data/www /data/code

    if [ ! -d ${BASEDIR}/conf/vhost ]; then
        mkdir ${BASEDIR}/conf/vhost -p
    fi

    cat >>${proxy_java_conf}<<EOF
fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
fastcgi_param  QUERY_STRING       \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE       \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;

fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI       \$document_uri;
fastcgi_param  DOCUMENT_ROOT      \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
fastcgi_param  REQUEST_SCHEME     \$scheme;
fastcgi_param  HTTPS              \$https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/;

fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
#fastcgi_param  REDIRECT_STATUS    200;
# fastcgi_param  PHP_VALUE      "open_basedir=$document_root:/tmp/";
EOF

    if [ -f ${BASEDIR}/conf/nginx.conf ]; then
        mv ${BASEDIR}/conf/nginx.conf ${BASEDIR}/conf/nginx.confbak${BACKTIME}
    fi
   
    nginx_conf=${BASEDIR}/conf/nginx.conf 
    cat >>${nginx_conf}<<EOF
user  www www;
worker_processes  2;
pid ${BASEDIR}/nginx.pid;
worker_rlimit_nofile 655350;
events {
    use epoll;
    worker_connections 2048;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    access_log off;
    error_log logs/error.log notice;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                     '"\$http_user_agent" "\$http_x_forwarded_for"\$request_time"';
    server_names_hash_bucket_size 128;
    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;
    client_max_body_size 300m;
    tcp_nopush      on;
    server_tokens   off;
    client_body_buffer_size 512k;
    proxy_connect_timeout 60;
    proxy_read_timeout    600;
    proxy_send_timeout    600;
    proxy_buffering off;
    proxy_buffer_size     16k;
    proxy_buffers         4 64k;
    proxy_busy_buffers_size 128k;
    proxy_temp_file_write_size 128k;
    
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.1;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml;
    gzip_vary   on;
    limit_conn_zone \$binary_remote_addr zone=perip:50m;
  
server {
    listen       80  default_server;
    server_name  _;
    access_log   off;
    return       444;
  }
    include vhost/*.conf;
}
EOF

#echo "...."

    if [ ! -f ${localhost_conf} ]; then
        cat >>${localhost_conf}<<EOF
server {
      listen       80;
      server_name localhost;
      location /{
                 root html;
                 index  index.html index.htm;
          }
}
EOF
    fi

    
    #管理脚本后续生成
    #systemctl start nginx.service
    #systemctl enable nginx.service


cat >>${nginx_service}<<EOF
[Unit]
Description=nginx
After=network.target
 
[Service]
Type=forking
ExecStart=${BASEDIR}/sbin/nginx
ExecReload=${BASEDIR}/sbin/nginx -s reload
ExecStop=${BASEDIR}/sbin/nginx -s quit
PrivateTmp=true
#EnvironmentFile=/etc/sysconfig/rdisc
#ExecStart=/sbin/rdisc \$RDISCOPTS
 
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start nginx.service
    systemctl enable nginx.service

} 

function firewall_cmd() {
    firewall-cmd --list-all &>/dev/null
    if [ $? -eq 0 ]; then
        firewall-cmd --zone=public --add-port=80/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=443/tcp --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
}


env_check
selinux_stop
rpm_install
code_install
nginx_config
firewall_cmd
