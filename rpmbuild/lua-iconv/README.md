### lua-iconv安装

```shell
# https://github.com/downloads/ittner/lua-iconv/lua-iconv-7.tar.gz
[root@58dd4708e8da tmp]# tar -zxvf lua-iconv-7.tar.gz
[root@58dd4708e8da tmp]# yum install luarocks
[root@58dd4708e8da tmp]# yum install lua-devel
[root@58dd4708e8da tmp]# cd lua-iconv-7/
[root@58dd4708e8da lua-iconv-7]# luarocks install lua-iconv
[root@58dd4708e8da lua-iconv-7]# make install
[root@58dd4708e8da lua-iconv-7]# ls /usr/lib64/lua/5.1/iconv.so -l
-rwxr-xr-x 1 root root 10400 Aug 15 10:11 /usr/lib64/lua/5.1/iconv.so

```

