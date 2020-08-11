#!/usr/bin/python
# -*- coding:UTF-8 -*-
import requests,json

old_gitlab_token = "FhGUqTghmez6s_UxGhC-"
new_gitlab_token = "sdefjxidnginxdfdfddss"
old_git_address = "http://192.168.0.188"#api version v3
new_git_address = "http://192.168.10.180"#api version v4

def getUserData():
    print("开始获取用户信息")
    #调用api获取用户数据
    resultAll=[]
    flag=True
    num=1
    while flag:
        resultJson = httpGet(old_git_address+"/api/v3/users", {"private_token":old_gitlab_token,"page":num,"per_page":100})
        if str(resultJson)=="[]":
            flag=False
        num+=1
        resultAll = resultAll + resultJson
    for line in resultAll:
        if line['name']=='Administrator':
            break
        print('user:'+line['username'])
        findR = getUsersInfo(line['username'])
        print("新gitlab用户:"+str(findR))

        if str(findR)=='[]':
            password = line['username']+"12345"
            adminFlag="false"
            if line['is_admin']:
                adminFlag="true"
            createJson = httpPost(new_git_address+"/api/v4/users", {"private_token":new_gitlab_token,"email":line['email'],"password":password,"username":line['username'],"name":line['name'],"skip_confirmation":"true", "admin":adminFlag})
            print(createJson)

            #修改密码 确保弹出修改密码页面
            ''' updateR = httpPut(new_git_address+"/api/v4/users/"+str(createJson['id']), {"private_token":new_gitlab_token,"password":password})
            print(updateR) '''

            if line['state']=='blocked':
                blockR = httpPost(new_git_address+"/api/v4/users/"+str(createJson['id'])+"/block", {"private_token":new_gitlab_token,"page":num,"per_page":100})
                print(blockR)
        else:
            print(line['username']+',用户已存在')
            #break
    print("获取用户信息成功")

def getGroupData():
    print("开始获取组信息")
    #调用api获取组数据
    resultAll=[]
    flag=True
    num=1
    while flag:
        resultJson = httpGet(old_git_address+"/api/v3/groups", {"private_token":old_gitlab_token,"page":num,"per_page":100})
        if str(resultJson)=="[]":
            flag=False
        num+=1
        resultAll = resultAll + resultJson
    for line in resultAll:
        path = line['path']
        print('开始导出组:'+path)
        createJson = httpPost(new_git_address+"/api/v4/groups", {"private_token":new_gitlab_token,"name":line['name'],"path":path,"description":line['description'],"visibility":"public"})
        print("导出组返回信息："+str(createJson))
        #获取组下用户信息准备添加到组
        findJson = getGroupUsersData(path, line['id'])
        for user in findJson:
            userInfo = getUsersInfo(user['username'])
            if str(userInfo)=="[]":
                print(user['username']+"用户不存在")
            else:
                addUsersToGroup(path, userInfo[0]['id'], user['username'], user['access_level'])
    print("获取组信息成功")

def getProjectData():
    print("开始获取工程信息")
    #调用api获取工程数据
    resultAll=[]
    flag=True
    num=1
    while flag:
        resultJson = httpGet(old_git_address+"/api/v3/projects/all", {"private_token":old_gitlab_token,"page":num,"per_page":1})
        if str(resultJson)=="{'message': '500 Internal Server Error'}":
            print("error num:%d" % (num))
        else:
            if str(resultJson)=="[]":
                flag=False
            resultAll = resultAll + resultJson
        num+=1
    #print(len(resultAll))
    #提取数据保存到csv
    csv_file = open("project.csv", "w", encoding='utf-8')
    csv_data = ''
    data_num=0
    for line in resultAll:
        if data_num!=0:
            csv_data+='\n'
        csv_data+=line['namespace']['path']+','+line['path']+','+line['name']
        data_num+=1
    print("工程总数:"+str(data_num))
    csv_file.write(csv_data)
    csv_file.close()
    #调用api发送数据到新gitlab
    for line in resultAll:
        print("工程开始：namespace_path:%s, name:%s,path:%s" % (line['namespace']['path'], line['name'], line['path']))
        namespace = getNamspaceData(line['namespace']['path'])
        visibility_level = line['visibility_level']
        visibility = "private"
        if visibility_level == 10:
            visibility = "internal"
        elif visibility_level == 20:
            visibility = "public"
        if namespace is None:
            continue
        projectInfo = getProjectInfo(line['path'], line['namespace']['path'])
        print("projectInfo:"+str(projectInfo))
        if projectInfo is None:
            projectInfo = httpPost(new_git_address+"/api/v4/projects", {"private_token":new_gitlab_token,"name":line['name'],"path":line['path'],"namespace_id":namespace['id'],"description":line['description'],"visibility":visibility})
        print("createInfo:"+str(projectInfo))
        findJson = getProjectUsersData(line['path_with_namespace'], line['id'])
        for user in findJson:
            userInfo = getUsersInfo(user['username'])
            if str(userInfo)=="[]":
                print(user['username']+"用户不存在")
            else:
                print("给用户添加工程权限"+line['path_with_namespace'])
                addUsersToProject(projectInfo['id'], userInfo[0]['id'], user['username'], user['access_level'])
    print("获取工程信息成功")

def getGroupUsersData(group_path, group_id):
    print("开始获取"+group_path+"组下所有用户信息")
    #调用api获取数据
    resultJson = httpGet(old_git_address+"/api/v3/groups/"+str(group_id)+"/members", {"private_token":old_gitlab_token,"per_page":100})
    print(resultJson)
    print("获取"+group_path+"组下所有用户信息成功")
    return resultJson

def getUsersInfo(username):
    print("开始获取"+username+"用户信息")
    #调用api获取数据
    resultJson = httpGet(new_git_address+"/api/v4/users", {"private_token":new_gitlab_token,"username":username})
    print(resultJson)
    print("获取"+username+"用户信息成功")
    return resultJson

def addUsersToGroup(group_path, user_id, username, access_level):
    print("将用户加入%s组,%d:%s用户,%s级别" % (group_path, user_id, username, access_level))
    #调用api获取数据
    resultJson = httpPost(new_git_address+"/api/v4/groups/"+group_path+"/members", {"private_token":new_gitlab_token,"user_id":user_id,"access_level":access_level})
    print(resultJson)
    print("将用户加入组成功")
    return resultJson

def getProjectUsersData(project_path, project_id):
    print("开始获取"+project_path+"工程下所有用户信息")
    #调用api获取数据
    resultJson = httpGet(old_git_address+"/api/v3/projects/"+str(project_id)+"/members", {"private_token":old_gitlab_token,"per_page":100})
    print(resultJson)
    print("获取"+project_path+"工程下所有用户信息成功")
    return resultJson

def addUsersToProject(project_id, user_id, username, access_level):
    print("将用户加入%d工程,%d:%s用户,%s级别" % (project_id, user_id, username, access_level))
    #调用api获取数据
    resultJson = httpPost(new_git_address+"/api/v4/projects/"+str(project_id)+"/members", {"private_token":new_gitlab_token,"user_id":user_id,"access_level":access_level})
    print(resultJson)
    print("将用户加入工程成功")
    return resultJson

def getNamspaceData(path):
    print("开始获取"+path+"工作空间信息")
    #调用api获取数据
    resultJson = httpGet(new_git_address+"/api/v4/namespaces", {"private_token":new_gitlab_token,"per_page":100, "search":path})
    print(resultJson)
    if len(resultJson) > 0:
        for line in resultJson:
            if path==line['path']:
                print("获取"+path+"工作空间成功")
                return line
        print("获取"+path+"工作空间失败，未找到工作空间")
    else:
        print("获取"+path+"工作空间失败，返回值为空")

def getProjectInfo(path, namespace_path):
    print("开始获取"+path+"工程信息")
    #调用api获取数据
    resultJson = httpGet(new_git_address+"/api/v4/projects", {"private_token":new_gitlab_token,"per_page":100, "search":path})
    print(resultJson)
    if len(resultJson) > 0:
        for line in resultJson:
            if namespace_path==line['namespace']['path'] and path==line['path']:
                print("获取"+path+"工程成功")
                return line
        print("获取"+path+"工程失败，未找到工程")
    else:
        print("获取"+path+"工程失败，返回值为空")

def httpGet(url, data):
    result = requests.get(url, data=data)
    result.encoding = 'utf-8'
    resultJson = json.loads(result.text)
    return resultJson

def httpPost(url, data):
    result = requests.post(url, data=data)
    result.encoding = 'utf-8'
    resultJson = json.loads(result.text)
    return resultJson

def httpPut(url, data):
    result = requests.put(url, data=data)
    result.encoding = 'utf-8'
    resultJson = json.loads(result.text)
    return resultJson

#批量修改组权限
def updateGroupData():
    print("开始获取组信息")
    #调用api获取组数据
    resultAll=[]
    flag=True
    num=1
    while flag:
        resultJson = httpGet(new_git_address+"/api/v4/groups", {"private_token":new_gitlab_token,"page":num,"per_page":100})
        if str(resultJson)=="[]":
            flag=False
        num+=1
        resultAll = resultAll + resultJson
    print(len(resultAll))
    for line in resultAll:
        createJson = httpPut(new_git_address+"/api/v4/groups/"+str(line['id']), {"private_token":new_gitlab_token,"visibility":"public"})
        print(createJson)


getUserData()
getGroupData()
getProjectData()