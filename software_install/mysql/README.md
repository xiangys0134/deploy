## 1.mysql_rpm-x-x-x.sh版本支持

该脚本为rpm包安装，安装版本见版本号x-x-x

## 2. mysql_code-x-x-x.sh版本支持

该脚本为源码编译，安装版本见版本号x-x-x

## 3.mysql-5.7注意事项

MySQL5.7安全系数提升，第一层登录mysql时的密码可以去mysql的错误日志中找，如果没有则免密登陆；

mysql创建数据库等操作时会再次提示修改密码，以下操作即可：

alter  user 'root'@'localhost' identified by 'xxx';


