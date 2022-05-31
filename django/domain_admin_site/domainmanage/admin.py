from django.contrib import admin
from domainmanage.models import DomainInfo,Whoiscompany,Dnsservername

# Register your models here.


class DomainInfoAdmin(admin.ModelAdmin):
    '''域名信息模型'''
    list_per_page = 10  #指定每页显示10条数据
    list_display = ['dname','port','isDeploy','project','dnsserver',"domainserver"]
    actions_on_bottom = True
    actions_on_top = False
    list_filter = ['dname','project']
    search_fields = ['dname','project']

    def dnsserver(self,obj):
        try:
            ret = obj.mdnsservername.name
            return ret
        except Exception as e:
            return

    dnsserver.short_description = u"dns解析运营商"

    def domainserver(self,obj):
        try:
            ret = obj.dwhoiscompany.name
            return ret
        except Exception as e:
            return
    domainserver.short_description = u"域名注册商"

    # def isdeploy(self,obj):
    #     return obj.isDeploy
    # isdeploy.short_description = u"部署状态"


class WhoiscompanyAdmin(admin.ModelAdmin):
    '''域名运营商模型'''
    list_per_page = 10  #指定每页显示10条数据
    list_display = ['name',]
    actions_on_bottom = True
    actions_on_top = False
    list_filter = ['name']
    search_fields = ['name']

class DnsservernameAdmin(admin.ModelAdmin):
    '''dns服务商模型管理器'''
    list_per_page = 10
    list_display = ['name']
    actions_on_bottom = True
    actions_on_top = False

admin.site.register(DomainInfo,DomainInfoAdmin)
admin.site.register(Whoiscompany,WhoiscompanyAdmin)
admin.site.register(Dnsservername,DnsservernameAdmin)
