from django.http import HttpResponse
from xadmin.plugins.actions import BaseActionView


class ClearAction(BaseActionView):
    '''清空action'''
    action_name = "clear_score"    # 相当于这个Action的唯一标示, 尽量用比较针对性的名字
    description = u'清空成绩 %(verbose_name_plural)s'  # 出现在 Action 菜单中名称
    model_perm = 'change'       # 该 Action 所需权限
    icon = 'fa fa-bug'

    # 执行的动作
    def do_action(self, queryset):
        for obj in queryset:
            # 需执行model对应的字段
            obj.score = '0'     # 重置score为0
            obj.save()
        # return HttpResponse
        return None  # 返回的url地址