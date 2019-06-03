Name:	nginx-14.2	
Version:	1.14.2
Release:	1%{?dist}
Summary:	GUN nginx-1.14.2

Group:		Application/WebServer
License:	GPL
URL:		http://www.github.com/xiangys0134
Source0:	master.zip
Source1:	nginx-1.14.2.tar.gz
Source2:	nginx_config.tar.gz

#BuildRequires:	gcc>=4.4.7,gcc-c++>=4.4.7,pcre-devel>=8.12,openssl-devel>=1.0.1e,patch>=2.7.1,unzip>=2.11,make>=3.82
BuildRequires:	gcc,gcc-c++,pcre-devel,openssl-devel,patch,unzip,make
#Requires:	

%description
nginx-1.14.2

%prep
if [ ! -d /opt/nginx ]; then
    mkdir -p /opt/nginx
fi

if [ -d /opt/nginx/nginx_upstream_check_module-master ]; then
    rm -rf /opt/nginx/nginx_upstream_check_module-master
fi

cp -rf  $RPM_BUILD_DIR/nginx_upstream_check_module-master /opt/nginx/

groupadd nginx && useradd -d /var/cache/nginx -g nginx -s /sbin/nologin nginx


%build
cd $RPM_BUILD_DIR/nginx-1.14.2
patch -p1 < /etc/nginx/nginx_upstream_check_module-master/check_1.14.0+.patch
./configure \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib64/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=nginx \
--group=nginx \
--with-compat \
--with-file-aio \
--with-threads \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_random_index_module \
--with-http_realip_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC' \
--add-module=/opt/nginx/nginx_upstream_check_module-master \
--with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'

%install
cd $RPM_BUILD_DIR/nginx-1.14.2
make && make install 
mkdir -p %{buildroot}/usr/share/nginx
mkdir -p %{buildroot}/usr/share/nginx/html
mkdir -p %{buildroot}/usr/lib/systemd/system
mkdir -p %{buildroot}/usr/sbin
mkdir -p %{buildroot}/var/cache
mkdir -p %{buildroot}/var/log
mkdir -p %{buildroot}/opt/nginx
mkdir -p %{buildroot}/var/log/nginx
#mkdir -p %{buildroot}/etc/nginx
#cp -rf /etc/nginx %{buildroot}/etc/
%{__install} -p -D -m 0755 /etc/nginx %{buildroot}/etc/nginx
mkdir -p %{buildroot}/etc/nginx/conf.d
cp -rf $RPM_BUILD_DIR/nginx_config/html/* %{buildroot}/usr/share/nginx/html/
/bin/cp -rf $RPM_BUILD_DIR/nginx_config/conf/nginx.conf %{buildroot}/etc/nginx/conf/
/bin/cp -rf $RPM_BUILD_DIR/nginx_config/conf/default.conf %{buildroot}/etc/nginx/conf.d/
#cp -rf /etc/sysconfig/nginx %{buildroot}/etc/sysconfig/nginx
#cp -rf /etc/sysconfig/nginx-debug %{buildroot}/etc/sysconfig/nginx-debug
cp -rf $RPM_BUILD_DIR/nginx_config/system/nginx-debug.service %{buildroot}/usr/lib/systemd/system/
cp -rf $RPM_BUILD_DIR/nginx_config/system/nginx.service %{buildroot}/usr/lib/systemd/system/
#cp -rf /usr/lib64/nginx %{buildroot}/usr/lib64/nginx
#cp -rf /usr/libexec/initscripts/legacy-actions/nginx %{buildroot}/usr/libexec/initscripts/legacy-actions/nginx
#cp -rf /usr/sbin/nginx %{buildroot}/usr/sbin/
#cp -rf /usr/share/man/man8/nginx.8.gz %{buildroot}/usr/share/man/man8/nginx.8.gz
#cp -rf /var/cache/nginx %{buildroot}/var/cache/
#cp -rf /opt/nginx/nginx_upstream_check_module-master %{buildroot}/opt/nginx/
%{__install} -p -D -m 0755 /usr/sbin/nginx %{buildroot}/usr/sbin/nginx
%{__install} -p -D -m 0755 /var/cache/nginx %{buildroot}/var/cache/nginx
%{__install} -p -D -m 0755 /opt/nginx/nginx_upstream_check_module-master %{buildroot}/opt/nginx/nginx_upstream_check_module-master

%post
id nginx &>/dev/null
if [ $? -ne 0 ]; then
    groupadd nginx && useradd -d /var/cache/nginx -g nginx -s /sbin/nologin nginx
else
    echo "user:nginx exist"
    echo "please mkdir -p /var/cache/nginx/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}"
fi

%files
%doc
/etc/nginx
/etc/nginx/conf.d
#/etc/nginx/conf.d
#/etc/nginx/conf.d/default.conf
#/etc/nginx/fastcgi_params
#/etc/nginx/koi-utf
#/etc/nginx/koi-win
#/etc/nginx/mime.types
#/etc/nginx/modules
%config /etc/nginx/nginx.conf
#/etc/nginx/scgi_params
#/etc/nginx/uwsgi_params
#/etc/nginx/win-utf
/usr/lib/systemd/system/nginx-debug.service
/usr/lib/systemd/system/nginx.service
/usr/share/nginx
/usr/share/nginx/html
/usr/share/nginx/html/50x.html
/usr/share/nginx/html/index.html
/var/log/nginx
/var/cache/nginx
/opt/nginx/nginx_upstream_check_module-master
%config /etc/nginx/nginx.conf
%config /etc/nginx/conf.d/default.conf

%changelog

