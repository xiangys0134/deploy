#!/bin/bash
#yousong.xiang 2018.10.11
#v1.0.2
#

[ -f /etc/profile ] && . /etc/profile

cmd=`pwd`
datetime=`date '+%H%M%S'`
log=upgrade${datetime}.log

if [ ! -f ${log} ]; then
    touch ${log}
fi

check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

epel_install() {
    #关闭selinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
    setenforce 0
    #判断是否安装redhat-lsb-core
    if [ `check_rpm redhat-lsb-core` == 0 ]; then
        yum install -y redhat-lsb-core  >/dev/null >&1
    fi 
  
    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`
    
    #source /etc/profile
    #判断是否安装remi-release,如果没有安装则安装
    if [ `check_rpm remi-release` == 0 ]; then
        rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-${sys_ver}.rpm  &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "\033[32;1mremi-release install seccuess\033[0m" |tee -a ${log}
        else
            echo -e "\033[31;1mremi-release install fail\033[0m" |tee -a ${log}
        fi
    fi   

}

php_fpm_conf() {
    num=$1
    php_ver=$2
    php_fpm_cf=$3
    username=nginx
  
   #[ -f /var/log/php_install.lock ] && echo -e '\033[31;1mPHP Already installed\033[0m';return 5

    id nginx &>/dev/null 
    if [ $? -ne 0 ]; then
        groupadd nginx
        useradd -M -g nginx -s /sbin/nologin  nginx
    fi
    

    if [ ! -f ${php_fpm_cf} ]; then  
        echo "******************************************************************"
cat >>${php_fpm_cf}<< EOF
[web${num}]
;fpm监听端口，即nginx中php处理的地址，一般默认值即可。可用格式为: 'ip:port', 'port', '/path/to/unix/socket'. 每个进程池都需要设置。如果nginx和php在不同的机器上，分布式处理，就设置ip这里就可以了。
;listen = 127.0.0.1:9000
listen = /var/run/php-fpm/php-fpm-${php_ver}-web${num}.sock
;listen.allowed_clients = 127.0.0.1
;允许访问FastCGI进程的IP白名单，设置any为不限制IP，如果要设置其他主机的nginx也能访问这台FPM进程，listen处要设置成本地可被访问的IP。默认值是any。每个地址是用逗号分隔. 如果没有设置或者为空，则允许任何服务器请求连接。
;backlog数，设置 listen 的半连接队列长度，-1表示无限制，由操作系统决定，此行注释掉就行。
listen.backlog = 2048
;unix socket设置选项，如果使用tcp方式访问，这里注释即可。 
listen.owner = ${username}
listen.group = ${username}
listen.mode = 0666
;启动进程的用户和用户组，FPM 进程运行的Unix用户, 必须要设置。用户组，如果没有设置，则默认用户的组被使用。
user = nginx
group = nginx
;每一个请求的访问日志，默认是关闭的。
;access.log = log/.access.log
;设定访问日志的格式。
;access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"
;php-fpm进程启动模式，pm可以设置为static和dynamic和ondemand 如果选择static，则进程数就数固定的，由pm.max_children指定固定的子进程数。
pm = dynamic
;如果选择dynamic，则进程数是动态变化的,由以下参数决定：
pm.max_children = 256                                                                 ;子进程最大数
pm.start_servers = 15                                                                 ;启动时的进程数，默认值为: min_spare_servers + (max_spare_servers - min_spare_servers) / 2
pm.min_spare_servers = 15                                                             ;保证空闲进程数最小值，如果空闲进程小于此值，则创建新的子进程
pm.max_spare_servers = 30                                                             ;保证空闲进程数最大值，如果空闲进程大于此值，此进行清理
pm.max_requests = 500                                                                 ;设置每个子进程重生之前服务的请求数. 对于可能存在内存泄漏的第三方模块来说是非常有用的. 如果设置为 '0' 则一直接受请求. 等同于 PHP_FCGI_MAX_REQUESTS 环境变量. 默认值: 0.
pm.status_path = /php-fpm-${num}-status-web2                                          ;FPM状态页面的网址. 如果没有设置, 则无法访问状态页面. 默认值: none. munin监控会使用到
ping.path = /php-fpm-${num}-ping-web2                                                 ;FPM监控页面的ping网址. 如果没有设置, 则无法访问ping页面. 该页面用于外部检测FPM是否存活并且可以响应请求. 请注意必须以斜线开头 (/)
ping.response = pong                                                                  ;用于定义ping请求的返回相应. 返回为 HTTP 200 的 text/plain 格式文本. 默认值: pong.
request_terminate_timeout = 60s                                                       ;设置单个请求的超时中止时间. 该选项可能会对php.ini设置中的'max_execution_time'因为某些特殊原因没有中止运行的脚本有用. 设置为 '0' 表示 'Off'.当经常出现502错误时可以尝试更改此选项。
request_slowlog_timeout = 60s                                                         ;当一个请求该设置的超时时间后，就会将对应的PHP调用堆栈信息完整写入到慢日志中. 设置为 '0' 表示 'Off'
slowlog = /var/log/php-fpm/www-slow.log                                               ;慢请求的记录日志,配合request_slowlog_timeout使用，默认关闭
rlimit_files = 10240                                                                  ;设置文件打开描述符的rlimit限制. 默认值: 系统定义值默认可打开句柄是1024，可使用 ulimit -n查看，ulimit -n 2048修改。
security.limit_extensions = .php .php3 .php4 .php5                                    ;设置php允许执行的文件，默认只允许执行.php文件。
php_admin_value[error_log] = /var/log/php-fpm/www-${num}-error.log                    ;php_admin_value[error_log] 参数 会覆盖php.ini中的 error_log 参数
php_admin_flag[log_errors] = on                                                       ;记录错误信息(保存到日志文件中)
php_admin_value[date.timezone] = Asia/Shanghai                                        ;增加参数，默认 date.timezone 是被注释掉的，也就是默认时区是 utc,设置php时区
php_value[session.save_handler] = files                                               ;session的存储方式
php_value[session.save_path] = /var/lib/php/session                                   ;session id存放路径
php_admin_value[upload_max_filesize] = 20M
php_admin_value[post_max_size] = 20M
php_admin_value[memory_limit] = 256M                                                  ;memory_limit主要是为了防止程序错误，或者死循环占用大量的内存，导致系统宕机。在引入大量三方插件，或者代码时，进行内存限制就非常有必要了。
;php_admin_value[disable_functions] = exec,popen,system,passthru,shell_exec,escapeshellarg,escapeshellcmd,proc_close,proc_open
;使用disable_functions限制程序使用一些可以直接执行系统命令的函数如system，exec，passthru，shell_exec，proc_open等等。
;php_admin_value[disable_functions] = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server
;php_admin_value[open_basedir] =  /data/www/:/tmp/:/home/www/
;upload_tmp_dir 的这个参数为上传文件的临时目录，需要 php 进程有读写权限。
php_admin_value[upload_tmp_dir] =  /tmp 

EOF

    fi

    if [ $? -eq 0 ]; then
        echo -e "\033[32;1m生成$num:php-fpm配置文件成功\033[0m" |tee -a ${log}
    fi

}

install_php() {
    #以下两个变量可根据yum安装不同版本和socket进行调整
    #number=2
    #php_version=5.5

    [ -f /var/log/php_install.lock ] && {
                                            echo -e '\033[31;1mPHP Already installed\033[0m' |tee -a ${log}
                                            return 5
                                        }
    #安装epel源
    epel_install
    php55w_repo=/etc/yum.repos.d/webtatic.repo
    php55w_gpg_key=/etc/pki/rpm-gpg/RPM-GPG-KEY-webtatic-el7

    [ -f ${php55w_repo} ] && rm -rf ${php55w_repo};rm -rf ${php55w_gpg_key}

    #添加yum源,下面的判定适用于自建yum源,对应的进行修改
    rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
    rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

    if [ ! -f ${php55w_repo} ]; then
        #安装php源
        #rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
        #rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

        #只限于centos7环境安装
        cat >>${php55w_repo}<< EOF
[webtatic]
name=Webtatic Repository EL7 - \$basearch
baseurl=http://repo.webtatic.com/webtatic/yum/el7/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-webtatic-el7

[webtatic-debuginfo]
name=Webtatic Repository EL7 - \$basearch - Debug
baseurl=http://repo.webtatic.com/webtatic/yum/el7/\$basearch/debug/
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-webtatic-el7

[webtatic-source]
name=Webtatic Repository EL7 - \$basearch - Source
baseurl=http://repo.webtatic.com/webtatic/yum/el7/SRPMS/
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-webtatic-el7

EOF

    fi

    if [ ! -f ${php55w_gpg_key} ];then
cat >>${php55w_gpg_key}<< EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

mQINBFOch44BEADUQkO69WbI65GuTf7e/PxkPMONyyjeV3wZjz1qHtDbryzQmoN9
CJg4xLUd/Dd03peNRQJ7RL/l2qsCu1Mb7zSTqaDdExRGyweKw6mIGBumzvBBRXPw
97ezIEIiEmq3ZUKFGBSDU3VQI4Zzndn/NgSOa03tWn2VlrTyYsMHm07839OGn6bD
CdnxlzAv2Z6FxYKomo2jMNPQ9vyJ6h3dSUghFhAkZPlkfLPAdBxuFVnn3oyAElDa
F8G19BfRywg7tLQRE7aSuX9E7VqJo0QmZPqwy/oijb9NSEyDg9lO+y/naebX67NJ
L51+RdAXWBxAk3FtSANTz9v3LgszCTDpeSLgAz2zvwsAyuI/GbF0qPhv0QPsnQ+9
ipbZoRTVo6zqBSITdK4kKs9WQXwYq40KzFFcL0d/fruYwCIAkOpBKJPCRYcX2rWj
usbuXBei9bB6aGFo5txLHoACpBh9eR4RDkEtcFrfnCJBWGs/JleyxFoL+jn4F+Nc
V73zWuSaYBmc7AMsE/3nu4iEOvYMDJB6KG7Vqz++ZIM2jjuyT4ujATpJlzr2SyIh
LlKhOLEv8sHZfqjzuN8eStycbSTm6EWQLR5R2oZODgI29hMk2C04JQ26+WjtJnr4
U43bPgh39qTkXwjU+5kCb0D5YixIcvMFsTm4i2bEBBvD+0i0BU2eHbRMMwARAQAB
tCBXZWJ0YXRpYyBFTDcgPHJwbXNAd2VidGF0aWMuY29tPokCOQQTAQIAIwUCU5yH
jgIbAwcLCQgHAwIBBhUIAgkKCwQWAgMBAh4BAheAAAoJEOh/0jZi50yl0HQQAJzN
8/eq1aN38Uk/x0STbbcdmn4vKkYYP3asrz7LWWU6IPacEc4LDkpc/YumzllE3suw
/wISvg7G4hZohQIdnCOoqkZo7OTUbHKkDJZykhqOI8Fs+6Tc2UQnLA3+uTHthKeF
JBjiRD6LxwSdoPulHDFBEPNOr1gqo3bHS40PxjxX3kFYnv8CR59MXcOLiy3aaVhA
Szj+BHhtDQ95xCxW2Z0jpHJ3F5fM9RAl5kR1hjtvvXjq8DbLn8HjHfJyvitSKMoI
jBAl32er5nrattBAKgnvGNA+CRR7b5VuOvHbl/xih4GpSKxCjkRFjwbnV0JYOXcf
Q9C2Y2750qlRU1hTcPr7Suc/dK7lgzuCEtLIzwMp+22OvF0LLV5FCAGIr3MErC5S
ZZBwH7V44AUpvWJgO6+ral3Yn3BHjPazZu52Nj1A9PX3D+7M2iVWGmyADAS5pFbt
8RnOzEzTRqKVL37K1C8gaxkx1j8pNDdjTSk0JZeCcyi3dsPTe+wsdbfude1jzD8r
XUUW6y4OjQfWknGJpvQ7bfYkoYvINCWqdwUgaOGmrQ8omkeO4AjHsJ41/elz5FN6
yG86FITDM4P64H8PBSCkFUYaYXrnWHWftjGcrGF6cFjZGLDh/pWL0vBgB7u+LoMa
EFPgVyg6CysBrTAT061QVX9O1bJTtxXAcG2vr/kv
=D3Nr
-----END PGP PUBLIC KEY BLOCK-----
EOF

    fi
    
    #检查php55w是否安装
    if [ `check_rpm php55w-common` == 0 ]; then
        yum --enablerepo=webtatic install -y libssh2-devel php55w php55w-devel php55w-opcache php55w-mbstring php55w-mcrypt php55w-mysqlnd php55w-fpm php55w-xml php55w-gd php55w-xmlrpc php55w-pecl-redis php55w-pecl-apcu php55w-bcmath php55w-pecl-igbinary php55w-pecl-memcache php55w-gearman php55w-memcached php55w-msgpack php55w-posix php55w-shmop php55w-soap php55w-sysvmsg php55w-sysvsem php55w-sysvshm php55w-zip php55w-pear php55w-pecl-xdebug php55w-pecl-amqp php55w-pecl-swoole php55w-pecl-mongodb openssl openssl-devel mysql-community-client python python-devel python-pip
    fi 
    if [ $? -ne 0 ]; then
        echo "\033[31;1mphp install false\033[0m" |tee -a ${log}
        exit 6
    fi   

    if [ -z "${number}" ]; then
        let number=2
    fi 
    
    if [ -z "${php_version}" ]; then
        php_version=5.5
    fi

    [ -f /etc/php-fpm.d/www.conf ] && mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.default     

    #for((i=1;i<${num};i++));do
    #    php_fpm_conf $i ${php_ver} /etc/php-fpm.d/web${num}.conf
    #done 
    let i=1
    while [ $i -le ${number} ]
    do
        php_fpm_conf $i ${php_version} /etc/php-fpm.d/web${i}.conf
        let i++
    done 

   cd ${cmd}
   #安装安装ZendGuardLoader解密扩展
   wget http://downloads.zend.com/guard/7.0.0/zend-loader-php5.5-linux-x86_64_update1.tar.gz
   tar -zxf zend-loader-php5.5-linux-x86_64_update1.tar.gz
   if [ ! -f /lib64/php/modules/ZendGuardLoader.so ]; then
       cp ${cmd}/zend-loader-php5.5-linux-x86_64/ZendGuardLoader.so /lib64/php/modules/
       chmod +x /lib64/php/modules/ZendGuardLoader.so
   fi

    #生成ZendGuard配置文件
    if [ ! -f /etc/php.d/20-zendguardloader.ini ]; then
        cat >>/etc/php.d/20-zendguardloader.ini<< EOF
zend_extension=ZendGuardLoader.so
zend_loader.enable = 1
zend_loader.disable_licensing = 0
zend_loader.obfuscation_level_support = 3            
EOF
    fi


    #安装php-ssh2扩展
    #if [ ! -f /usr/lib64/php/modules/ssh2.so ]; then
    #    yum install -y gcc-c++ make >/dev/null >&1
    #    echo -e "\n"|/bin/pecl install ssh2 >/dev/null >&1
#cat >>/etc/php.d/20-ssh2.ini<< EOF
#extension=ssh2.so   
#EOF
#    fi

   touch /var/log/php_install.lock

}


function python36() {
    cd ${cmd}
    if [ `check_rpm python36` == 0 ]; then
        yum install -y python36 python36-devel python36-setuptools python36-six.noarch
        wget -P /tmp/ https://bootstrap.pypa.io/get-pip.py
        /bin/python36 /tmp/get-pip.py
        ln -s /bin/python36 /bin/python3
        /usr/local/bin/pip3 install pandas
        /usr/local/bin/pip3 install sxl
    else
            echo -e  "supervisor 已安装,无需安装." |tee -a ${log}
    fi
}



case $1 in
  php)
    install_php
    python36
    ;;
  *)
    echo $"Usage: $0 {web|php|mysql}"
    exit 4
esac
