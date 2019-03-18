配置zabbix
yum install -y sysstat

agent端配置
vi /etc/zabbix/zabbix_agentd.conf

添加如下内容：
UserParameter=disk.discovery[*],/etc/zabbix/scripts/disk_discovery.sh
UserParameter=disk.status[*],/etc/zabbix/scripts/disk_status.sh $1 $2

[root@localhost scripts]# systemctl restart zabbix-agent.service

服务端进行测试：
zabbix_get -s 192.168.182.129 -k 'disk.discovery[*]'

四、zabbix
配置-模板-template os linux-自动发现规则 -创建发现规则
名称：Disk Discovery
键值：disk.discovery



## ansible推送模块至远端Agent

一、安装ansible

[root@localhost ~]# yum install ansible



二、配置主机群组

[root@localhost ~]# cd /etc/ansible/

[root@localhost ansible]# vi hosts

[zabbix]

192.168.40.128 ansible_ssh_user="opadm" ansible_ssh_pass=123456 ansible_ssh_port=22

192.168.40.130 ansible_ssh_user="opadm" ansible_ssh_pass=123456 ansible_ssh_port=22



[root@localhost ansible]# ssh -p 22  opadm@192.168.40.128            //预先连接

[root@localhost ansible]# ssh -p 22 opadm@192.168.40.130                     //预先连接



[root@localhost ansible]# ansible zabbix -m ping -s        //连接测试

![img](file:///C:/Users/Administrator/Documents/My Knowledge/temp/e6ddb870-0572-4627-aaea-66fed865d36f/128/index_files/692742b4-6a2b-43d5-bac2-23216341231d.png)



三、推送zabbix

[root@test-db monitor_sh]# tar -czvf /tmp/monitor_sh.tar.gz *                        //分别备份两个目录中的文件

[root@test-db zabbix_agentd.d]# tar -czvf /tmp/zabbix_agentd.d.tar.gz *



[root@localhost tmp]# ansible zabbix -m copy -a 'src=/tmp/zabbix_mode.sh dest=/tmp' -s        //将脚本推送至远端机器

[root@localhost tmp]# ansible zabbix -m copy -a 'src=/tmp/zabbix_agentd.d.tar.gz dest=/tmp' -s    //将模板推送至远端

[root@localhost tmp]# ansible zabbix -m copy -a 'src=/tmp/monitor_sh.tar.gz dest=/tmp' -s

[root@localhost tmp]# cat /tmp/zabbix_mode.sh 

```shell
#!/bin/bash
# ansible推送模板到远端脚本
[ -f /etc/profile ] && . /etc/profile

if [ ! -d /etc/zabbix/zabbix_agentd.d ]; then

​    mkdir -p /etc/zabbix/zabbix_agentd.d

fi 



if [ ! -d /etc/zabbix/monitor_sh ]; then

​    mkdir -p /etc/zabbix/monitor_sh

fi
```

[root@localhost tmp]# ansible zabbix -m shell -a 'bash /tmp/zabbix_mode.sh' -s        //远端执行脚本

[root@localhost tmp]# ansible zabbix -m shell -a 'tar -zxvf /tmp/monitor_sh.tar.gz -C /etc/zabbix/monitor_sh/' -s    //命令解压缩

[root@localhost tmp]# ansible zabbix -m shell -a 'tar -zxvf /tmp/zabbix_agentd.d.tar.gz -C /etc/zabbix/zabbix_agentd.d/' -s



[root@localhost tmp]# ansible 192.168.40.130 -m shell -a '/etc/init.d/zabbix-agent restart' -s        //重启zabbix-agent，这里区分客户端版本

[root@localhost tmp]# ansible 192.168.40.128 -m shell -a 'systemctl restart zabbix-agent.service' -s    //重启zabbix-agent，这里区分客户端版本