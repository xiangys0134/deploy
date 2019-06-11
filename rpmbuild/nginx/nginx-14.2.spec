Name:	nginx-14.2	
Version:	1.14.2
Release:	1%{?dist}
Summary:	GUN nginx-1.14.2

Group:		Application/WebServer
License:	GPL
URL:		http://www.github.com/xiangys0134
Source0:	master.zip
Source1:	nginx_config.tar.gz
#Source2:	nginx_upstream_check_module-master.tar.gz
Source2:	nginx-1.14.2.tar.gz

#BuildRequires:	gcc>=4.4.7,gcc-c++>=4.4.7,pcre-devel>=8.12,openssl-devel>=1.0.1e,patch>=2.7.1,unzip>=2.11,make>=3.82
BuildRequires:	gcc,gcc-c++,pcre-devel,openssl-devel,patch,unzip,make
#Requires:	

%description
nginx-1.14.2

%prep
rm -rf $RPM_BUILD_DIR/nginx_upstream_check_module-master 
rm -rf $RPM_BUILD_DIR/nginx_config
rm -rf $RPM_BUILD_DIR/nginx-14.2
%setup -T -b 0 -n nginx_upstream_check_module-master -b 1 -n nginx_config -b 2 -n nginx-1.14.2

cd $RPM_BUILD_DIR
if [ ! -d /opt/nginx ]; then
    mkdir -p /opt/nginx
fi

if [ -d /opt/nginx/nginx_upstream_check_module-master ]; then
    rm -rf /opt/nginx/nginx_upstream_check_module-master
fi

cp -rf $RPM_BUILD_DIR/nginx_upstream_check_module-master /opt/nginx/

user_sum=`grep -w "^nginx" /etc/passwd|wc -l`
if [ ${user_sum} -eq 0 ]; then 
    groupadd nginx && useradd -d /var/cache/nginx -g nginx -s /sbin/nologin nginx
fi


%build
cd $RPM_BUILD_DIR/nginx-1.14.2
patch -p1 < /opt/nginx/nginx_upstream_check_module-master/check_1.14.0+.patch
./configure \
--prefix=/usr/local/nginx \
--user=nginx \
--group=nginx \
--with-pcre \
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
make

%install
#cd $RPM_BUILD_DIR/nginx-1.14.2
#make && make install 
#%{__rm} -rf $RPM_BUILD_ROOT
#%{__make}  install DESTDIR=%{buildroot}
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}


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
/usr/local/nginx
/usr/local/nginx/*
#%attr(0755,root,root) /etc/rc.d/init.d/nginx
%config(noreplace) /usr/local/nginx/conf/nginx.conf
%config(noreplace) /usr/local/nginx/conf/fastcgi_params

%changelog

