# 1.vsftpd简介
开放端口21(主动模式)、30000-30999(被动模式)

# 2.vsftpd管理用户
采用虚拟用户映射本地ftp用户
```
vi /etc/vsftpd/chroot_list 并写入值[guest_username=ftp]
```

# 3.生成vsftpd库文件
db_load -T -t hash -f /etc/vsftpd/ftpuser.txtx /etc/vsftpd/vftpuser.db

# 4.配置pam.d验证
[root@localhost vsftpd]# cat /etc/pam.d/vsftpd  
auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/vftpuser
account required /lib64/security/pam_userdb.so db=/etc/vsftpd/vftpuser

# 5.vsftpd密码信息
账号默认回车为admin，密码默认回车或者等待30秒则随机生成密码值



