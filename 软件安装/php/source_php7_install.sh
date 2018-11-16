#!/bin/bash
#yousong.xiang 2018.10.11
#v1.0.1
#源码安装php7
#
[ -f /etc/profile ] && . /etc/profile

cmd=`pwd`
url='http://soft.g6p.cn/deploy/source'
code='php-7.2.8'
soft_rpm="gcc gcc-c++ gd-devel libjpeg-devel libpng-devel freetype-devel libxml2-devel curl-devel zlib-devel libxml2-devel bzip2-devel libjpeg-devel"


init() {
    #安装依赖
    for i in ${soft_rpm}
    do
        echo "install ${i}...."
        yum install -y $i &>/dev/null
        if [ $? -ne 0 ]; then
            echo "\033[31;1msoft:${i} install false\033[0m"
        fi        
    done
}

install_php() {
     cd ${cmd}
     if [ -d ${cmd}/${code} ]; then
         rm -rf ${cmd}/${code}
     fi

     if [ ! -f ${cmd}/${code}.tar.gz ]; then
         wget ${url}/${code}.tar.gz
     fi

     tar -zxf ${code}.tar.gz
     
     cd ${cmd}/${code}
     ./configure \
     --prefix=/usr/local/php \
     --with-config-file-path=/etc \
     --with-config-file-scan-dir=/etc/php.d \
     --with-gd \
     --with-png-dir \
     --with-jpeg-dir \
     --with-freetype-dir \
     --enable-fpm \
     --with-mcrypt \
     --with-zlib \
     --enable-mbstring \
     --disable-pdo \
     --with-curl \
     --disable-rpath \
     --with-bz2 \
     --with-zlib \
     --enable-sockets \
     --enable-sysvsem \
     --enable-sysvshm \
     --enable-pcntl \
     --with-mhash \
     --enable-zip \
     --with-pcre-regex \
     --with-mysql

     if [ $? -ne 0 ]; then
         echo "\033[31;1mmake configure fail\033[0m"
         exit 5
     fi

     make && make install
     if [ $? -ne 0 ]; then
         echo "\033[31;1mmake source fail\033[0m"
         exit 9
     fi
}

case $1 in
  php)
    init
    install_php
    ;;
esac


