### 1.脚本介绍

pptp_rpm.1.7.2.sh目前仅在虚拟机环境上测试通过，微软云主机验证失败，目前可能所有云主机安装后都会连接失败，未解决

### 2.故障定位

#### 1.开启debug

/etc/ppp/options.pptpd 将#debug修改为debug，tail -f /var/log/messages查看pptp日志信息

#### 2.配置用户密码

默认会生成用户名密码，新增用户用以定位问题，# vi /etc/ppp/chap-secrets  添加shen pptpd 123456 * 

注释：创建了一个vpn用户：shen，口令：123456

#### 3.检查服务器是否开启转发

vi /etc/sysctl.conf 将net.ipv4.ip_forward = 0中的0改为1 sysctl -p生效

### 3.拨号成功后配置

#### 1.添加路由配置

route add -net dst(目标IP段) netmask 255.255.255.0 dev ppp0

#### 2.脚本

```shell
#!/bin/bash
[ -f /etc/profile ] && . /etc/profile

IsPPP0Exit()
{
   if ifconfig | grep ppp0 >/dev/null ;then
        return 1
   fi
   return 0
}

DialogToVPN()
{
   pkill pptp
   sleep 1
   pptpsetup --create pptpd --server 192.168.5.17 --username admin --password 1ee578c9b --encrypt --start
   sleep 1
   route add -net 192.168.5.0 netmask 255.255.255.0 dev ppp0
}

while(true)
do
   IsPPP0Exit
   if [ $? -eq 0 ]; then
      pkill pptp
      sleep 1
      pptpsetup --create pptpd --server 192.168.5.17 --username admin --password 1ee578c9b --encrypt --start
      sleep 1
      route add -net 192.168.5.0 netmask 255.255.255.0 dev ppp0
   fi
   sleep 10
done
```



备注：以上根据自身真实情况配置，服务脚本启动案例nohup bash a.sh &