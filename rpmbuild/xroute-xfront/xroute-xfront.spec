Name:xroute-xfront	
Version:dev_weiqi.li.27
Release:	1%{?dist}
Summary:xunce xroute-xfront service 	

Group:Applications
License:BSD
URL:http://www.xuncetech.com/		
Source0:xroute-xfront/

BuildRequires:make lua-iconv lua-devel	
Requires:protobuf >= 3.6.1 libuv >= 1.22.0 libzmq >= 4.2.1 spdlog >= 1.1.0 lua-iconv redis lua-socket

%description
xunce xroute-xfront service

%prep
if [ -d $RPM_BUILD_DIR/xroute-xfront ]; then
    rm -rf $RPM_BUILD_DIR/xroute-xfront
fi
mkdir -p $RPM_BUILD_DIR/xroute-xfront
cp -rf ${WORKSPACE}/* $RPM_BUILD_DIR/xroute-xfront

%build
source /etc/profile
cd $RPM_BUILD_DIR/xroute-xfront/
mkdir -p build && cd build
cmake ../
make %{?_smp_mflags}

%install
cd $RPM_BUILD_DIR/xroute-xfront/build
make install DESTDIR=%{buildroot}
mkdir -p %{buildroot}/data/xcrf/xrouter
cp -rf $RPM_BUILD_DIR/xroute-xfront/xrouter/bin/workspace/* %{buildroot}/data/xcrf/xrouter/
mkdir -p %{buildroot}/data/xcrf/xfront
cp -rf $RPM_BUILD_DIR/xroute-xfront/xfront/bin/workspace/* %{buildroot}/data/xcrf/xfront/
mkdir -p %{buildroot}/usr/lib/xcrf/thirdparty
cp -rf $RPM_BUILD_DIR/xroute-xfront/xfront/3rdparty/libt2sdk.so %{buildroot}/usr/lib/xcrf/thirdparty/
chmod -R 755 %{buildroot}/usr/lib/xcrf/
%{__install} -p -D -m 0755 /data/jenkins/build/xroute-xfront/xcrf.conf %{buildroot}/etc/ld.so.conf.d/xcrf.conf

%post
ldconfig
#add user opadm
grep -q "^opadm" /etc/passwd
if [[ $? -ne 0 ]];then
  groupadd -g 5002 opadm
  useradd -u 5002 -g opadm -G wheel  -d /home/opadm -m -s /bin/bash opadm
fi
#make log path and change owner
mkdir -p /data/xcrf/xrouter/logs
mkdir -p /data/xcrf/xfront/logs
chown -R opadm:opadm /data/xcrf/
chmod -R 755 /usr/lib/xcrf/



%files
%doc
/data/xcrf/
/usr/bin/xfront
/usr/bin/xroute
/usr/lib/xcrf/
/etc/ld.so.conf.d/xcrf.conf

%changelog
