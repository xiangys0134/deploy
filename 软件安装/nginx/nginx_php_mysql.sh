#!/bin/bash
#yousong.xiang 2018.9.30
#
#v1.0.1

[ -f /etc/profile ] && . /etc/profile
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ $# -ne 1 ] && {
                    echo "\033[31m传递参数有误\033[0m"
                    exit 9
                }

check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

remi_install() {
    #关闭selinux
    sed  -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    if [ "`check_rpm redhat-lsb-core`" == "0" ]; then
        yum install -y redhat-lsb-core >/dev/null 2>&1
        if [ "`check_rpm redhat-lsb-core`" != "0" ]; then
            echo "\033[31m安装redhat-lsb-core成功\033[0m"
        else
            echo "\033[31m安装redhat-lsb-core失败\033[0m"
        fi
    fi
}

#配置nginx虚拟站点配置文件
nginx_conf() {
    num=$1 
    fastcgi_conf=/etc/nginx/fastcgi.conf
    nginx_upstream_conf=/etc/nginx/conf.d/upstream.conf
    nginx_vhost_conf=/etc/nginx/conf.d/default_path_info.conf_default

    [ ! -f /etc/nginx ] && mkdir /etc/nginx -p
    [ ! -f /etc/nginx/conf.d ] && mkdir /etc/nginx/conf.d -p

    #如果num变量为空时，num赋值为1
    if [ -z "${num}" ]; then
        num=1
    fi

    if [ ! -f ${nginx_upstream_conf} ]; then
        echo "upstream web {" > ${nginx_upstream_conf}
        for ((i=1;i<=num;i++)); do
            echo "server unix:/var/run/php-fpm/php-fpm-5.5-web${num}.sock;" >> ${nginx_upstream_conf}
        done
        echo "}" >>${nginx_upstream_conf}
    else
        echo "\033[31m${nginx_upstream_conf}已经存在!\033[0m"
    fi

    #生成fastcgi.conf文件
    if [ ! -f ${fastcgi_conf} ]; then
        cat >>${fastcgi_conf}<< EOF
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
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;
# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;
# fastcgi_param  PHP_VALUE      "open_basedir=\$document_root:/tmp/";
EOF
    else
        echo "\033[31m${fastcgi_conf}已经存在!\033[0m"
    fi

    if [ ! -f ${nginx_vhost_conf} ]; then
    #生成nginx虚拟站点配置文件
    cat >>${nginx_vhost_conf}<< EOF
#nginx 虚拟主机模板,开启pathinfo。
server {
    listen              80;
    #listen            443;
    server_name         test.com; 
    index index.php index.html;
    charset utf8;
    gzip_min_length 1024;
    client_max_body_size    1000m;
    #ssl on;
    #ssl_certificate /data/virtualhost/test/ssl/test.pem;
    #ssl_certificate_key /data/virtualhost/test/ssl/test.key;
    #ssl_session_timeout 5m;
    #ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    #ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    #ssl_prefer_server_ciphers on;
    location / {
        charset utf8;
        root /data/virtualhost/test/wwwroot/web;
    if (-f $request_filename) {
            break;
        }
        if (!-e $request_filename){
            rewrite ^/(.*)$ /index.php/$1 last;
        }
    }
    location ~ .*\.php[/]? {
    root /data/virtualhost/test/wwwroot/web;
    include        fastcgi.conf;
    proxy_no_cache 1;
    proxy_store off;
    proxy_cache off;
    tcp_nodelay    on;
    fastcgi_pass   web;
    fastcgi_index index.php;
    fastcgi_connect_timeout 200;
    fastcgi_send_timeout 200;
    fastcgi_read_timeout 200;
    fastcgi_buffer_size 128k;
    fastcgi_buffers 4 256k;
    fastcgi_split_path_info ^(.+\.php)(.*)$;
    fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param   PATH_INFO      $fastcgi_path_info;
    fastcgi_param   PATH_TRANSLATED $document_root$fastcgi_path_info;
    }
    #设置访问日志和错误日志
    access_log /data/virtualhost/test/logs/access.log main;
    error_log /data/virtualhost/test/logs/error.log warn;
}
EOF
    else
        echo "\033[31m${nginx_vhost_conf}已经存在!\033[0m"
    fi

}

#CentOS 安装nginx
nginx_install() {
    num=$1
    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`
    if [ "`check_rpm nginx-release`" == "0" ]; then
        rpm -ivh http://nginx.org/packages/centos/${sys_ver}/noarch/RPMS/nginx-release-centos-${sys_ver}-0.el${sys_ver}.ngx.noarch.rpm >/dev/null >&1
        if [ "`check_rpm nginx-release`" != "0" ]; then
            echo "\033[32mnginx源安装成功\033[0m"
        else
            echo "\033[31mnginx源安装失败\033[0m"
        fi
    else
        echo "\033[31m已存在nginx源\033[0m" 
    fi
   
    if [ `check_rpm  nginx-1` == 0 ]; then
        yum install -y nginx ImageMagick >/dev/null >&1
        if [ `check_rpm  nginx-1` != 0 ]; then
            echo "\033[32mnginx安装成功\033[0m"
        else
            echo "\033[31mnginx安装失败\033[0m"
        fi
    fi

}

case "$1" in
  web)
        remi_install
        nginx_install
        nginx_conf    
esac

