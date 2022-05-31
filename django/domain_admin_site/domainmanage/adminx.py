import xadmin
from xadmin import views
from domainmanage.models import DomainInfo,Whoiscompany,Dnsservername
from .adminx_actions import ClearAction

class BaseSetting(object):

    enable_themes = True #开启主题选择

    use_bootswatch = True

class GlobalSettings(object):

    site_title = "运维管理系统"  #设置左上角title名字

    site_footer = "深圳菲客科技有限公司"  #设置底部关于版权信息

    #设置菜单缩放

    menu_style = "accordion"     #设置菜单样式

xadmin.site.register(views.BaseAdminView, BaseSetting)

xadmin.site.register(views.CommAdminView, GlobalSettings)


class DomainInfoAdmin(object):
    '''域名信息模型'''
    list_per_page = 10  #指定每页显示10条数据
    list_display = ['dname','port','isDeploy','project','mdnsservername',"dwhoiscompany"]
    actions_on_bottom = True
    actions_on_top = False
    list_filter = ['dname','project']
    search_fields = ['dname','project']
    # actions = [ClearAction,]


    def dnsserver(self,obj):
        try:
            ret = obj.mdnsservername.name
            print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>')
            print(ret)
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



class WhoiscompanyAdmin(object):
    '''域名运营商模型'''
    list_per_page = 10  #指定每页显示10条数据
    list_display = ['name',]
    actions_on_bottom = True
    actions_on_top = False
    list_filter = ['name']
    search_fields = ['name']

class DnsservernameAdmin(object):
    '''dns服务商模型管理器'''
    list_per_page = 10
    list_display = ['name']
    actions_on_bottom = True
    actions_on_top = False

xadmin.site.register(DomainInfo,DomainInfoAdmin)
xadmin.site.register(Whoiscompany,WhoiscompanyAdmin)
xadmin.site.register(Dnsservername,DnsservernameAdmin)
