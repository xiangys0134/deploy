## rabbitmq配置

安装完成后操作：

#### 1.增加用户并设置密码

rabbitmqctl add_user username password 		//例如：rabbitmqctl add_user tonyg 123

```html
#username 用户，自行定义
#password 密码，自行定义
```

#### 2.把用户设置为管理用户

rabbitmqctl set_user_tags username administrator		//例如：rabbitmqctl set_user_tags tonyg administrator

#### 3.创建虚拟主机

rabbitmqctl add_vhost test_host		//创建主机test_host

#### 4.授权用户所有权限

rabbitmqctl set_permissions -p test_host tonyg ".*" ".*" ".*"

```html
#test_host		虚拟主机
#tonyg			用户
```

#### 5.启动web管理接口

rabbitmq-plugins enable rabbitmq_management

```html
注意：启动web管理接口会提示你重启rabbitmq才会生效，这时就需要去重启rabbitmq
```

#### 6.重启rabbitmq服务

systemctl restart rabbitmq-server.service		

```html
重启完之后，系统会监听web端口15672,可通过ss -tunlp|grep 15672确定端口是否监听
```

