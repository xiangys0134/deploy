# 1.脚本介绍
该脚本主要功能为用来自动安装JDK，安装完成JDK后脚本会检索/var/log/jdk.lock文件以此来判断是否安装JDK。所以之后无法再通过该脚本进行安装tomcat

# 2.tomcat安装
如果需要安装多个tomcat请手动进行安装，脚本上tomcat的gz文件，该文件来着官网