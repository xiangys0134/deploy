%global __os_install_post %{nil}
%define XC_OSP_VERSION 100.100.1
%define XC_OSP_NAME xc-osp
Name:     %{XC_OSP_NAME}
Version:	%{XC_OSP_VERSION}
Release:	1%{?dist}
Summary:xunce osp

Group:Applications
License:BSD
URL:http://www.xuncetech.com/
Source0:xc-osp/

BuildRequires:java-1.8.0-openjdk java-1.8.0-openjdk-devel
Requires:java-1.8.0-openjdk

%description
xunce osp

%prep

%build
source ~/.bashrc && source /etc/profile
mvn clean compile verify -P prod -Dmaven.test.skip=true

%install
mkdir -p %{buildroot}/data/xc-osp/all_libs
srvname=`ls $RPM_BUILD_DIR/ |grep -v "pom.xml" |grep -v "db" |grep -v "doc" |grep -v "README.md"|grep -v "common-client"`
for srv in ${srvname}
do
    cp -rf $RPM_BUILD_DIR/${srv}/target/${srv}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist.zip %{buildroot}/data/xc-osp/
    cd %{buildroot}/data/xc-osp
    unzip %{buildroot}/data/xc-osp/${srv}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist.zip &>/dev/null
    #ls %{buildroot}/data/xc-osp/${srv}/lib/ |grep "jar" &>/dev/null
    mv -f %{buildroot}/data/xc-osp/${srv}/lib/*.jar %{buildroot}/data/xc-osp/all_libs/
    rm -rf %{buildroot}/data/xc-osp/${srv}/lib/
    rm -rf %{buildroot}/data/xc-osp/${srv}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist.zip
done

#mkdir -p %{buildroot}/data/xc-osp/{db,doc}
#cp -rf $RPM_BUILD_DIR/db/* %{buildroot}/data/xc-osp/db/
#cp -rf $RPM_BUILD_DIR/doc/* %{buildroot}/data/xc-osp/doc/

%post
srvname=`ls /data/xc-osp/ |grep -v "all_libs" |grep -v "db"|grep -v "doc"|grep -v "common-client"`
for srv in ${srvname}
do
    ln -sf /data/xc-osp/all_libs /data/xc-osp/${srv}/lib
done

echo -e "\033[32m 请到仓库版本号doc下查看本次版本发布文档!!! \033[0m"
echo -e "\033[32m 请到仓库版本号db下手动执行sql脚本!!! \033[0m"
echo -e "\033[32m [安装完成] 程序主目录为/data/xc-osp/ \033[0m"

%files
%doc
/data/xc-osp/
%config /data/xc-osp/config-service/config/userservice/user-service-prod.yml
%config /data/xc-osp/config-service/config/oauthservice/oauth-service-prod.yml
%config /data/xc-osp/config-service/config/quartzservice/quartz-service-prod.yml
%config /data/xc-osp/config-service/config/gateway/gateway-service-prod.yml
%config /data/xc-osp/config-service/config/fileservice/file-service-prod.yml
%config /data/xc-osp/monitor-service/config/application.yml


%changelog
