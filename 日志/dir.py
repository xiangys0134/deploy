#!/usr/bin/python
# -*- coding: utf-8 -*-
#日志处理邮件发送
#yousong.xiang QQ:250919938 2018.8.23
#v1.0.0

import re,os,sys,time,socket,commands,smtplib,zipfile,datetime

#import smtplib
from smtplib import SMTP_SSL
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email import encoders
from email.header import Header

file2_tb = "/tmp/files.txt"


#file_tmp变量用来存放报错信息
file_tmp = "/tmp/file_tmp.txt"
logspath_error = '/data/backup/err_logs'
#file1 = "/tmp/file_tmp.txt"

if os.path.exists(file2_tb):
    os.remove(file2_tb)

if os.path.exists(file_tmp):
    os.remove(file_tmp)

os.chdir('/tmp')


class clean:
    def __init__(self, file_url):
        self.file_url = file_url
    def delfile(self):
        f =  list(os.listdir(self.file_url))
        print("%s\n  开始清理过期文件...." % self.file_url)
        for i in range(len(f)):
            filedate = os.path.getmtime(self.file_url + f[i])
            time1 = datetime.datetime.fromtimestamp(filedate).strftime('%Y-%m-%d')
            date1 = time.time()
            num1 =(date1 - filedate)/60/60/24
            if num1 >= 30:
                try:
                    os.remove(self.file_url + f[i])
                    print(u"已删除文件：%s ： %s" %  (time1, f[i]))
                except Exception as e:
                        print(e)
        else:
            pass

##邮件发送
def msg_send(user,password,receivers,title,content,*args):
    sender = user
    passwd = password
    #receivers = receivers
    #receiver = ','.join(receivers)
    mail_host = 'smtp.qiye.163.com'
    msg = MIMEMultipart()
    msg['From'] = sender
    msg['To'] = ','.join(receivers)
    #msg['Subject'] = title
    msg['Subject'] = Header(title,'utf-8')
    # 邮件正文
    msg.attach(MIMEText(content, 'plain', 'utf-8'))

    date_time = time.strftime('%Y%m%d%H%M%S', time.localtime())
    if os.path.exists(logspath_error) == False:
        os.makedirs(logspath_error)

    logs_zip = 'logs_%s.zip'%(date_time)
    # if os.path.exists(logs_zip):
    #     os.remove(logs_zip)

    z = zipfile.ZipFile(logs_zip, 'w', zipfile.ZIP_STORED)
    for file_txt in args:

        if os.path.exists(file_txt):
            print file_txt
            z.write(file_txt)
    z.close()

    os.system('mv %s %s'%(logs_zip,logspath_error))
    file1 = clean(logspath_error + '/')
    file1.delfile()
    #os.system('cd %s;find  -name *.zip -type f -mtime +3 -exec rm -rf {} \\;'%(logspath_error))
    # file = MIMEText(open(logs_zip, 'rb').read(), 'base64', 'utf-8')
    # file['Content-Type'] = 'application/octet-stream'
    # file['Content-Disposition'] = 'attachment; filename= %s'%(logs_zip)
    # msg.attach(file)


    try:
         #smtpObj = smtplib.SMTP()
         smtpObj = smtplib.SMTP_SSL(mail_host, 465)
         #smtpObj.connect(mail_host, 25)
         smtpObj.login(sender, passwd)
         smtpObj.sendmail(sender,receivers,msg.as_string())
         print 'Success'
    except smtplib.SMTPException:
         print 'Error'


#sourcdir = sys.argv[1]
##hostname_err变量为传递
#hostname_err = sys.argv[2]


#变量tb1用来存储错误日志路径、行数
tb1 = {}

def get_mac_address():
    mac=uuid.UUID(int = uuid.getnode()).hex[-12:]
    return ":".join([mac[e:e+2] for e in range(0,11,2)])


#获取本机电脑名
#myname = socket.getfqdn(socket.gethostname())
#获取本机ip
#myaddr = socket.gethostbyname(myname)


def get_host_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()

    return ip


#各个子系统日志
def xc_logs():
    a = os.popen('find /data/www/*/storage/logs -type d')
    line = a.readlines()
    for i in line:
        print i
        os.system('python /data/script/logs_check.py %s'%(i.replace('\n','')))

#系统级别日志
def system_logs():
    #msg1_dir = "/var/cache/nginx/.pm2/logs"
    msg1_dir = "/var/log"
    #msg1_log = "xc-live-tunnel-error.log"
    msg1_log = "messages"
    os.system('python /data/script/logs_check.py %s %s'%(msg1_dir,msg1_log))

#获取本机计算机名
myname = commands.getstatusoutput('hostname')[1]
#获取本机IP地址
myaddr = get_host_ip()



#收集应用系统日志
xc_logs()

#收集系统级别日志
system_logs()


f3 = open(file_tmp,"a+")
file_lines = f3.read()
f3.close()

file2_list = []

if os.path.exists(file2_tb):
    f4 = open(file2_tb,'r')
    for i in f4:
        i = i.strip()
        file2_list.append(i)
    f4.close()



if file_lines:
    msg_send('ops@test.com', 'abc',['yousong.xiang@test.com'],'日志:' + myaddr + myname,file_lines,*file2_list)

for i in file2_list:
    i = i.strip()
    if os.path.exists(i):
        print i
        os.remove(i)

