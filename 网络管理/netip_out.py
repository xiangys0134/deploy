#!/user/bin/env python3
# -*- coding: utf-8 -*-

import requests
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email import encoders
from email.header import Header

##邮件发送
##user,pwd,to,header_txt,content_txt
def msg_send(user,pwd,to,header_txt,content_txt):
    msg = MIMEMultipart()
    msg['Subject'] = Header(header_txt,'utf-8')
    msg['From'] = Header(user)

    content1 = MIMEText(content_txt,'plain', 'utf-8')
    msg.attach(content1)

    s = smtplib.SMTP('smtp.sina.com')
    s.set_debuglevel(1)              #调试使用
    s.starttls()                    #建议使用
    s.login(user, pwd)
    s.sendmail(user, to, msg.as_string())
    s.close()


content_txt = requests.get("https://icanhazip.com/").text.strip()


header_txt = '公司外网ip'
msg_send('xiangys_0134@sina.com', '123456', ['xiangys0134@163.com'], header_txt, str(content_txt))