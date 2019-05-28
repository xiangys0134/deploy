%define _prefix    /usr/local/php7
%define _user      nginx
%define _group     nginx
%define _home %{_localstatedir}/cache/nginx
# distribution specific definitions
%define use_systemd (0%{?fedora} && 0%{?fedora} >= 18) || (0%{?rhel} && 0%{?rhel} >= 7) || (0%{?suse_version} == 1315)

%define name      php
%define summary   PHP for Webserver
%define version   2.1.2
%define release   1
%define license   GPL
%define group     Application/WebServer
%define source    %{name}-%{version}.tar.gz
%define url       http://www.xuncetech.com
%define vendor    xuncetech

 
Name:           php
Version:        7.2.5 
Vendor:         xuncetech
Release:        1
Summary:        GUN php-7.2.5
 
Group:          Application/WebServer
License:        GPL
URL:            http://www.xuncetech.com
Source0:        %{name}-%{version}.tar.gz
Source1:        web1.conf 
Source2:        opcache.ini

BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root 
 
#Requires:  gcc>=4.4.7, gcc-c++>=4.4.7, zlib-devel>=1.2.3, pcre-devel>=8.12, openssl-devel>=1.0.1e, autoconf>=2.63, automake>=1.11.1
#Requires:      mhash-devel
Requires:      libxml2-devel
Requires:      libcurl-devel 
Requires:      openssl-devel
BuildRequires:  libxml2-devel
BuildRequires:  libcurl-devel
BuildRequires:  openssl-devel
 
%description
The GNU PHP WEB Server program. 
 
%prep

%setup -q 
 
%build
./configure \
    --prefix=%{_prefix} \
    --with-config-file-path=%{_prefix}/etc \
    --with-config-file-scan-dir=%{_prefix}/etc/php.d/ \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-iconv \
    --with-zlib \
    --with-openssl \
    --with-xmlrpc \
    --with-gettext \
    --with-curl \
    --with-mhash \
    --with-fpm-user=%{_user} \
    --with-fpm-group=%{_group} \
    --with-libzip \
    --with-pear \
    --enable-xml \
    --enable-pdo \
    --enable-bcmath \
    --enable-shmop \
    --enable-sysvsem \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-fpm \
    --enable-json \
    --enable-mbstring \
    --enable-ftp \
    --enable-pcntl \
    --enable-sockets \
    --enable-soap \
    --enable-session \
    --disable-ipv6 \
    --enable-opcache  
make
 
 
%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make}  install INSTALL_ROOT=$RPM_BUILD_ROOT
%{__mkdir} -p %{buildroot}/var/log/php-fpm
%{__mkdir} -p %{buildroot}/var/run/php-fpm
%{__mkdir} -p %{buildroot}/var/lib/php/session
%{__mkdir} -p %{buildroot}%{_prefix}/etc/php.d
%{__install} -p -D -m 0644 php.ini-production %{buildroot}%{_prefix}/etc/php.ini
%{__install} -p -D -m 0644 %{buildroot}%{_prefix}/etc/php-fpm.conf.default %{buildroot}%{_prefix}/etc/php-fpm.conf
%{__install} -p -D -m 0644 %{SOURCE1} %{buildroot}%{_prefix}/etc/php-fpm.d/web1.conf
%{__install} -p -D -m 0644 %{SOURCE2} %{buildroot}%{_prefix}/etc/php.d/opcache.ini

%if %{use_systemd}
# install systemd-specific files
%{__mkdir} -p $RPM_BUILD_ROOT%{_unitdir}
%{__install} -m644 sapi/fpm/php-fpm.service %{buildroot}%{_unitdir}/php7-fpm.service
%else
# install SYSV init stuff
%{__mkdir} -p $RPM_BUILD_ROOT%{_initrddir}
%{__install} -m755 sapi/fpm/init.d.php-fpm $RPM_BUILD_ROOT%{_initrddir}/php7-fpm
%endif
 
rm -rf %{buildroot}/{.channels,.depdb,.depdblock,.filemap,.lock}

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%doc
%defattr(-,root,root)
%{_prefix}
/var/log/php-fpm
/var/run/php-fpm
%{_prefix}/etc/php.d
/var/lib/php/session
%config(noreplace) %{_prefix}/etc/php.ini
%config(noreplace) %{_prefix}/etc/php-fpm.conf
%config(noreplace) %{_prefix}/etc/php-fpm.d/web1.conf
%config(noreplace) %{_prefix}/etc/php.d/opcache.ini
%{_unitdir}/php7-fpm.service

%pre
# Add the "nginx" user
getent group %{_group} >/dev/null || groupadd -r %{_group}
getent passwd %{_user} >/dev/null || \
    useradd -r -g %{_group} -s /sbin/nologin \
    -d %{_home} -c "nginx user"  %{_user}
exit 0

%post
# Register the php7-fpm service
if [ $1 -eq 1 ]; then
%if %{use_systemd}
    /usr/bin/systemctl preset php7-fpm.service >/dev/null 2>&1 ||:
%else
    /sbin/chkconfig --add php7-fpm
%endif
fi	
	
%preun
if [ $1 -eq 0 ]; then
%if %use_systemd
    /usr/bin/systemctl --no-reload disable php7-fpm.service >/dev/null 2>&1 ||:
    /usr/bin/systemctl stop php7-fpm.service >/dev/null 2>&1 ||:
%else
    /sbin/service php7-fpm stop > /dev/null 2>&1
    /sbin/chkconfig --del php7-fpm
%endif
fi



