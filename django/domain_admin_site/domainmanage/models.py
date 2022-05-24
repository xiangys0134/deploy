from django.db import models

# Create your models here.

class DomainInfo(models.Model):
    '''域名信息模型类'''
    dname = models.CharField(max_length=60,unique=True,blank=True,verbose_name='域名主机')
    port = models.IntegerField(default=443)
    project = models.CharField(max_length=50,null=True,verbose_name='所属项目')
    #标记删除
    # isDelete = models.BooleanField(default=False)
    # 标记是否部署
    isDeploy = models.BooleanField(default=True,verbose_name='部署状态')

    # 关系属性
    dwhoiscompany = models.ForeignKey('Whoiscompany',on_delete=models.CASCADE,null=True,verbose_name='域名注册商')

    #关系属性
    mdnsservername = models.ForeignKey('Dnsservername',on_delete=models.CASCADE,null=True,verbose_name='dns运营商')

    class Meta:
        db_table = 'domaininfo'
        verbose_name = u'域名地址'
        verbose_name_plural = verbose_name

    def __str__(self):
        return self.dname

class Whoiscompany(models.Model):
    '''基于whois认证'''
    name = models.CharField(max_length=20,unique=True,blank=True)
    # url = models.CharField(max_length=100)

    class Meta:
        db_table = 'whoiscompany'
        verbose_name = u'域名注册商'
        verbose_name_plural = verbose_name

    def __str__(self):
        return self.name


class Dnsservername(models.Model):
    '''dns服务名模型类'''
    name = models.CharField(max_length=50,unique=True)

    class Meta:
        db_table = 'dnsservername'
        verbose_name = u'DNS运营商'
        verbose_name_plural = verbose_name

    def __str__(self):
        return self.name







