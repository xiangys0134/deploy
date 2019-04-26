### ```CentOS系统在线安装php扩展```

#### ```protobuf扩展```

```shell
pecl install protobuf
cd /etc/php.d/
echo "extension=protobuf.so" >> protobuf.ini
//安装完成后，检查一下是否成功安装：
php -m | grep protobuf
```

#### ```zmq扩展```

```shell
yum install zeromq-devel
pecl install zmq-beta
cd /etc/php.d/
echo "extension=zmq.so" >> zmq.ini
//安装完成后，检查一下是否成功安装：
php -m | grep zmq
```

```!!!记得重启php相关服务```

### ```CentOS系统离线安装php扩展```

#### ```protobuf扩展```

```shell
[root@localhost ~]# tar -zxvf php_centos.tar.gz
[root@localhost ~]# cd php_centos/
[root@localhost php_centos]# yum localinstall *rpm

//protobuf扩展安装
[root@localhost tmp]# tar -zxvf protobuf-3.7.1.tgz
[root@localhost tmp]# cd protobuf-3.7.1/
[root@localhost protobuf-3.7.1]# phpize
[root@localhost protobuf-3.7.1]# ./configure
[root@localhost protobuf-3.7.1]# make
[root@localhost protobuf-3.7.1]# make test
[root@localhost protobuf-3.7.1]# make install
[root@localhost protobuf-3.7.1]# cd /etc/php.d/
[root@localhost php.d]# echo "extension=protobuf.so" >> protobuf.ini

//安装完成后，检查一下是否成功安装：
php -m | grep protobuf
```

#### ```zmq扩展```

```shell
//zmq扩展安装
[root@localhost tmp]# tar -zxvf zmq-1.1.3.tgz
[root@localhost tmp]# cd zmq-1.1.3/
[root@localhost zmq-1.1.3]# phpize
[root@localhost zmq-1.1.3]# ./configure
[root@localhost zmq-1.1.3]# make
[root@localhost zmq-1.1.3]# make test
[root@localhost zmq-1.1.3]# make install
[root@localhost zmq-1.1.3]# cd /etc/php.d/
[root@localhost php.d]# echo "extension=zmq.so" >> zmq.ini

//安装完成后，检查一下是否成功安装：
php -m | grep zmq
```

```!!!记得重启php相关服务```

### ```Ubuntu系统在线安装php扩展```

#### ```protobuf扩展```

```shell
apt-get update
apt-get install libpcre3-dev
pecl install protobuf
cd /etc/php5/mods-available		//php模块配置文件存放路径，默认安装在此目录，不排除例外
echo "extension=protobuf.so" >> protobuf.ini
cd /etc/php5/fpm/conf.d			//因php版本不同，如果该目录不存在，则无需进入此目录建立软连接	
ln -s ../../mods-available/protobuf.ini protobuf.ini		//配置软连接
cd /etc/php5/cli/conf.d/
ln -s ../../mods-available/protobuf.ini protobuf.ini		//配置软连接

//安装完成后，检查一下是否成功安装：
php -m | grep protobuf
```

#### ```zmq扩展```

```shell
apt-get install libzmq3-dev
apt-get install pkg-config
pecl install zmq-beta
cd /etc/php5/mods-available
echo "extension=zmq.so" >> zmq.ini
cd /etc/php5/fpm/conf.d		//因php版本不同，如果该目录不存在，则无需进入此目录建立软连接	
ln -s ../../mods-available/zmq.ini zmq.ini
cd /etc/php5/cli/conf.d/
ln -s ../../mods-available/zmq.ini zmq.ini

//安装完成后，检查一下是否成功安装：
php -m | grep zmq

```

```!!!记得重启php相关服务```

### ```Ubuntu系统离线安装php扩展```

#### ```protobuf扩展```

```shell
//protobuf扩展安装
root@ubuntu:/tmp# tar -zxvf php_ubuntu.tar.gz
root@ubuntu:/tmp# cd php_ubuntu/
root@ubuntu:/tmp/php_ubuntu# dpkg -i libpcre3-dev_1%3a8.31-2ubuntu2.3_amd64.deb
root@ubuntu:/tmp/php_ubuntu# dpkg -l |grep libpcre33		//查看是否成功安装libpcre3-dev:amd64
root@ubuntu:/tmp# tar -zxvf protobuf-3.7.1.tgz
root@ubuntu:/tmp# cd protobuf-3.7.1/
root@ubuntu:/tmp/php-protobuf# phpize
root@ubuntu:/tmp/php-protobuf# ./configure
root@ubuntu:/tmp/php-protobuf# make
root@ubuntu:/tmp/php-protobuf# make install
cd /etc/php5/mods-available		//php模块配置文件存放路径，默认安装在此目录，不排除例外
echo "extension=protobuf.so" >> protobuf.ini
cd /etc/php5/fpm/conf.d								//因php版本不同，如果该目录不存在，则无需进入此目录建立软连接	
ln -s ../../mods-available/protobuf.ini protobuf.ini		//配置软连接
cd /etc/php5/cli/conf.d/
ln -s ../../mods-available/protobuf.ini protobuf.ini		//配置软连接

//安装完成后，检查一下是否成功安装：
php -m | grep protobuf
```

#### ```zmq扩展```

```shell
//zmq扩展安装
root@ubuntu:/tmp# cd php_ubuntu/
root@ubuntu:/tmp/php_ubuntu# dpkg -i libzmq3_4.0.4+dfsg-2ubuntu0.1_amd64.deb
root@ubuntu:/tmp/php_ubuntu# dpkg -i libzmq3-dev_4.0.4+dfsg-2ubuntu0.1_amd64.deb
root@ubuntu:/tmp/php_ubuntu# dpkg -l |grep libzmq3-dev		//检查是否安装成功

root@ubuntu:/tmp/php_mod# dpkg -i pkg-config_0.26-1ubuntu4_amd64.deb
root@ubuntu:/tmp/php_mod# dpkg -l |grep pkg-config		//检查是否安装成功

root@ubuntu:/tmp# tar -zxvf zmq-1.1.3.tgz
root@ubuntu:/tmp# cd zmq-1.1.3/
root@ubuntu:/tmp/zmq-1.1.3# phpize
root@ubuntu:/tmp/zmq-1.1.3# ./configure
root@ubuntu:/tmp/zmq-1.1.3# make
root@ubuntu:/tmp/zmq-1.1.3# make test
root@ubuntu:/tmp/zmq-1.1.3# make install
cd /etc/php5/mods-available				
echo "extension=zmq.so" >> zmq.ini
cd /etc/php5/fpm/conf.d					//因php版本不同，如果该目录不存在，则无需进入此目录建立软连接
ln -s ../../mods-available/zmq.ini zmq.ini
cd /etc/php5/cli/conf.d/
ln -s ../../mods-available/zmq.ini zmq.ini

//安装完成后，检查一下是否成功安装：
php -m | grep zmq
```

```!!!记得重启php相关服务```