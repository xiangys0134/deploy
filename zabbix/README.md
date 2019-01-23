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
