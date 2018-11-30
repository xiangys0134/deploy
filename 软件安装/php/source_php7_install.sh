#!/bin/bash
#Description: php7.2.8源码安装
#Author: yousong.xiang 
#Date: 2018.11.29
#version: v1.0.2
[ -f /etc/profile ] && . /etc/profile

cmd=`dirname $0`
url='http://soft.g6p.cn/deploy/source'
#soft_rpm=" gcc-c++ gd-devel libjpeg-devel libpng-devel freetype-devel libxml2-devel curl-devel zlib-devel libxml2-devel bzip2-devel libjpeg-devel"

if [ $# -ne 1 ]; then
    echo -e "\033[31m传递参数有误\033[0m"
    exit 9
fi

function check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

function epel_install() {
    #关闭selinux,安装基础依赖环境函数
    sed -i '/^SELINUX=.*/s/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
    setenforce 0
    #判断是否安装redhat-lsb-core
    if [ `check_rpm redhat-lsb-core` == '0' ]; then
        yum install -y redhat-lsb-core  >/dev/null >&1
    fi 

    if [ `check_rpm epel-release` == '0' ]; then
        yum install -y epel-release
    fi

    #重新加载环境变量 
    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`
    echo ${sys_ver}    

    #判断是否安装remi-release,如果没有安装则安装
    if [ `check_rpm remi-release` == '0' ]; then
        rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-${sys_ver}.rpm  &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "\033[32;1mepel-release install seccuess\033[0m"
            yum clean all            
        else
            echo -e "\033[31;1mepel-release install fail\033[0m"
        fi
    fi   

    if [ `check_rpm wget` == '0' ]; then
        yum install -y wget
    fi
}

function init() {
    #安装依赖
    soft_rpm="gcc-c++ gd-devel openssl-devel libjpeg-devel libpng-devel freetype-devel libxml2-devel curl-devel zlib-devel libxml2-devel bzip2-devel libjpeg-devel"
    for i in ${soft_rpm}
    do
        echo "install ${i}...."
        yum install -y $i &>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "\033[31;1msoft:${i} install false\033[0m"
        fi        
    done
}

function php7_install() {
     php7_dir="/usr/local/php7"
     php_code='php-7.2.8'
     
     #echo "aaaaa"
     cd ${cmd}

     if [ -f /var/log/php7.lock ]; then
         echo -e "\033[31;1m php7已经安装\033[0m"
         return 4
     fi

     if [ -d ${cmd}/${php_code} ]; then
         rm -rf ${cmd}/${php_code}
     fi

     if [ ! -f ${cmd}/${php_code}.tar.gz ]; then
         wget ${url}/${php_code}.tar.gz
     fi

     tar -zxf ${php_code}.tar.gz
     
     cd ${cmd}/${php_code}
     ./configure \
     --prefix=${php7_dir} \
     --with-config-file-path=${php7_dir}/etc \
     --with-config-file-scan-dir=${php7_dir}/etc/php.d/ \
     --with-mysqli=mysqlnd \
     --with-pdo-mysql=mysqlnd \
     --with-iconv \
     --with-zlib \
     --with-openssl \
     --with-xmlrpc \
     --with-gettext \
     --with-curl \
     --with-mhash \
     --with-fpm-user=web \
     --with-fpm-group=web \
     --with-libzip \
     --with-pear \
     --enable-xml \
     --enable-pdo \
     --enable-bcmath \
     --enable-shmop \
     --enable-sysvsem \
     --enable-inline-optimization \
     --enable-mbregex \
     --enable-fpm \
     --enable-json \
     --enable-mbstring \
     --enable-ftp \
     --enable-pcntl \
     --enable-sockets \
     --enable-soap \
     --enable-session \
     --disable-ipv6 \
     --enable-opcache

     if [ $? -ne 0 ]; then
         echo -e "\033[31;1mmake configure fail\033[0m"
         exit 5
     fi

     make && make install
     if [ $? -ne 0 ]; then
         echo -e "\033[31;1mmake source fail\033[0m"
         exit 9
     fi

     ${php7_dir}/bin/php --version
 
     if [ -f ${cmd}/${php_code}/php.ini-production ] && [ -d ${php7_dir}/etc ]; then
         cp ${cmd}/${php_code}/php.ini-production ${php7_dir}/etc/php.ini  
     fi

     if [ -f ${cmd}/${php_code}/sapi/fpm/php-fpm.service ] && [ -d /usr/lib/systemd/system ]; then
         cp ${cmd}/${php_code}/sapi/fpm/php-fpm.service /usr/lib/systemd/system/php7-fpm.service
     fi

     if [ -f ${cmd}/${php_code}/etc/php-fpm.conf.default ] && [ -d ${php7_dir}/etc ]; then
         cp ${cmd}/${php_code}/etc/php-fpm.conf.default ${php7_dir}/etc/php-fpm.conf
     fi

     if [ -f ${php7_dir}/etc/php-fpm.d/www.conf.default ]; then
         cp ${php7_dir}/etc/php-fpm.d/www.conf.default ${php7_dir}/etc/php-fpm.d/www.conf
     fi

     if [ ! -d ${php7_dir}/etc/php.d ]; then
         mkdir ${php7_dir}/etc/php.d -p
     fi
  
     echo "zend_extension=opcache.so" > /${php7_dir}/etc/php.d/opcache.ini
     
     if [ -f ${php7_dir}/bin/phpize ]; then
         if [ ! -f /bin/phpize ]; then
             ln -s ${php7_dir}/bin/phpize /bin/phpize
         fi
     fi

     cd ${cmd}
     
     echo -e "\n"|${php7_dir}/bin/pecl install redis
     echo "extension=redis.so" > ${php7_dir}/etc/php.d/redis.ini
     if [ `id www &>/dev/null` -ne 0 ]; then
         groupadd www
         useradd  -g www -M -s /sbin/nologin www
     fi
     
     sed -i "s/web/wwww/g" ${php7_dir}/etc/php-fpm.d/www.conf

     echo "php_admin_value[memory_limit] = 512M" >> ${php7_dir}/etc/php-fpm.d/www.conf
     echo "php_admin_value[upload_max_filesize] = 20M" >> ${php7_dir}/etc/php-fpm.d/www.conf
     echo "php_admin_value[post_max_size] = 20M" >> ${php7_dir}/etc/php-fpm.d/www.conf
     
     ln -s ${php7_dir}/bin/php /usr/bin/php7
    
     /bin/systemctl enable php7-fpm.service
     /bin/systemctl start php7-fpm.service
   
}


function php_beast() {
    php7_dir=/usr/local/php7
    beast_conf="/usr/local/php7/etc/php.d/50-beast.ini"
  
    cd ${cmd}
    echo `pwd`

    if [ -f ${beast_conf} ]; then
        echo -e "beast 已安装,无需安装."
        return 3
    fi

    if [ -d ${cmd}/php-beast-master ]; then
        rm -rf ${cmd}/php-beast-master
    fi

    if [ ! -f ${cmd}/php-beast-master.zip ]; then
        wget ${url}/php-beast-master.zip 
    fi
   
    if [ $? -ne 0 ]; then
        echo -e "\033[31;1mphp-beast-master.zip download fail\033[0m"
        return 7
    fi
    unzip php-beast-master.zip

    if [ `check_rpm autoconf` == "0" ]; then
        yum -y  install autoconf >/dev/null 2>&1
        if [ `check_rpm autoconf` != "0" ]; then
            echo -e "\033[32;1mautoconf 安装成功\033[0m"
        else
            echo -e "\033[32;1mautoconf 安装成功\033[0m"
        fi
    fi
    
    if [ -f ${php7_dir}/bin/phpize ]; then
        cd ${cmd}/php-beast-master
        ${php7_dir}/bin/phpize
        ./configure --with-php-config=${php7_dir}/bin/php-config
        make && make install
        
        if [ $? -ne 0 ]; then
            echo -e "\033[31;1mphp-beast 安装失败\033[0m"
            return 6
        else
            echo -e "\033[32;1mphp-beast 安装成功\033[0m"
        fi
        
    fi
 
    if [ ! -f ${beast_conf} ]; then
    cat >>${beast_conf}<< EOF
extension=beast.so
beast.log_file = "/tmp/php_beast.log"
EOF
    fi
    

}

function supervisorctl_install() {
    if [ `check_rpm supervisorctl` == "0" ]; then
        yum install -y supervisor
        if [ `check_rpm supervisor` != "0" ]; then
            echo -e "\033[32;1msupervisor 安装成功\033[0m"
        else
            echo -e "\033[31;1msupervisor 安装失败\033[0m"
        fi
    fi

}


case $1 in
  php)
    epel_install
    init
    php7_install
    php_beast
    supervisorctl_install
    ;;
  *)
    echo "USAG: $0 php"
    ;;
esac
