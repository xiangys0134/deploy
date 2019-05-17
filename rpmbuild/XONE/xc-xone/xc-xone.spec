Name:	xc-xone		
Version:	master.22	
Release:	1%{?dist}
Summary:	xunce xone

Group:		Applications
License:	BSD
URL:		https://github.com/xiangys0134
Source0:	xc-xone/

BuildRequires:	java-1.8.0-openjdk java-1.8.0-openjdk-devel fastdfs
Requires:	fastdfs java-1.8.0-openjdk

%description
xc-xone

%prep

%build
cd xc-xone
source /etc/profile
mvn clean compile verify -P prod -Dmaven.test.skip=true
if [ $? -ne 0 ]; then
    echo "mvn build failed"
    exit 8
fi

%install
mkdir -p %{buildroot}/data/xc-xone/all_libs
srvname=`ls /root/rpmbuild/BUILD/xc-xone/ |grep -v "pom.xml" |grep -v "db" |grep -v "doc"`
for srv in ${srvname}
do
    cp -r $RPM_BUILD_DIR/xc-xone/${srv}/target/${srv}-[0-9]*.[0-9]*.[0-9]*-SNAPSHOT-dist/${srv} %{buildroot}/data/xc-xone/
    mv -f %{buildroot}/data/xc-xone/${srv}/lib/*.jar %{buildroot}/data/xc-xone/all_libs/
    rm -rf %{buildroot}/data/xc-xone/${srv}/lib
done

mkdir -p %{buildroot}/data/xc-xone/sql_files
cp -r $RPM_BUILD_DIR/xc-xone/db/* %{buildroot}/data/xc-xone/sql_files

%post
srvname=`ls /data/xc-xone/ |grep -v "all_libs" |grep -v "sql_files"`
for srv in ${srvname}
do
    ln -sf /data/xc-xone/all_libs /data/xc-xone/${srv}/lib
done

echo -e "\033[32m 请到/data/xc-xone/sql_files下手动执行sql脚本!!! \033[0m"
echo -e "\033[32m [安装完成] 程序主目录为/data/xc-xone/ \033[0m"

%files
%doc
/data/xc-xone/
%config /data/xc-xone/config-server/config/gateway/gateway-prod.yml
%config /data/xc-xone/config-server/config/userservice/user-service-prod.yml
%config /data/xc-xone/config-server/config/oauthservice/oauth-service-prod.yml
%config /data/xc-xone/config-server/config/fileservice/file-service-prod.yml
%config /data/xc-xone/config-server/config/bond/bond-service-prod.yml
%config /data/xc-xone/tm-service/config/application.yml


%changelog

