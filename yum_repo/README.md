### centos7搭建yum私有仓库

#### 一、安装nginx

```shell
[root@xiangys0134-cdh02 ~]# wget https://raw.githubusercontent.com/xiangys0134/deploy/v1.0.13/software_install/nginx/nginx_rpm-1.14.sh && bash nginx_rpm-1.14.sh web

[root@xiangys0134-cdh02 ~]# cd /etc/nginx/conf.d/
[root@xiangys0134-cdh02 conf.d]# rm -rf ./*
[root@xiangys0134-cdh02 conf.d]# vim mirrors.conf
limit_conn_zone $binary_remote_addr zone=addr:10m;
server {
    listen 80;
    server_name mirrors.g6p.cn;
    location ~ ^/ {
        root /data/mirrors;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        autoindex_format html;
        limit_rate 20480k;
        access_log /data/logs/nginx/mirrors-access.log main;
        error_log /data/logs/nginx/mirrors-error.log;
    }
}

[root@xiangys0134-cdh02 conf.d]# mkdir -p /data/logs/nginx
[root@xiangys0134-cdh02 conf.d]# mkdir -p /data/mirrors

[root@xiangys0134-cdh02 conf.d]# systemctl start nginx.service
[root@xiangys0134-cdh02 conf.d]# systemctl enable nginx.service
```



#### 二、开始Nginx目录浏览功能

```shell
[root@xiangys0134-cdh02 conf.d]# vim /etc/nginx/nginx.conf
在http {下面添加以下内容：
autoindex on; #开启nginx目录浏览功能
autoindex_exact_size off; #文件大小从KB开始显示
autoindex_localtime on; #显示文件修改时间为服务器本地时间
:wq! #保存，退出
service nginx reload #重新加载配置

[root@xiangys0134-cdh02 conf.d]# systemctl restart nginx.service
```



#### 三、制作YUM仓库

```shell
3.1创建createrepo
[root@xiangys0134-cdh02 ~]# yum -y install createrepo yum-utils
yum源目录：
fedora-epel
mysql-repo
nodejs-repo
webtatic
xunce
```



#### 四、同步mysql

```shell
# bash /data/scripts/mysql_repos.sh
```



