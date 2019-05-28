%global php_extdir %(/usr/local/php7/bin/php-config --extension-dir 2>/dev/null || echo "undefined")
%global php_path   %(/usr/local/php7/bin/php-config --prefix  2>/dev/null || echo "undefined")

%define use_systemd (0%{?fedora} && 0%{?fedora} >= 18) || (0%{?rhel} && 0%{?rhel} >= 7) || (0%{?suse_version} == 1315)

Name: php7-beast
Version: 1.0.0
Release: 1%{?dist}
Summary: The phpredis extension provides an API for communicating with the Redis key-value store.

Group: Development/Languages
License: PHP
URL: http://pecl.php.net/package/beast
Source0: php-beast-%{version}.zip
BuildRoot: %_topdir/BUILDROOT

Requires: php
BuildRequires: php >= 7.0.0

%description
The beast extension provides an API for communicating with the beast store.

%prep
%setup -q -n php-beast-master

%build
%{php_path}/bin/phpize
./configure --with-php-config=%{php_path}/bin/php-config
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{php_extdir}
make install INSTALL_ROOT=%{buildroot}


#rpm安装后执行的脚本
%post
if [ $1 == 1 ];then
    echo "extension=beast.so" > %{php_path}/etc/php.d/50-beast.ini
    echo "beast.log_file = \"/tmp/php_beast.log\"" >> %{php_path}/etc/php.d/50-beast.ini
fi

if [ $1 -eq 0 ]; then
%if %use_systemd
    /usr/bin/systemctl restart php7-fpm.service >/dev/null 2>&1 ||:
%else
    /sbin/service php7-fpm restart > /dev/null 2>&1
%endif
fi

#rpm卸载前执行的脚本
%preun
if [ $1 -eq 0 ]; then
%if %use_systemd
    /usr/bin/systemctl stop php7-fpm.service >/dev/null 2>&1 ||:
    rm -f %{php_path}/etc/php.d/50-beast.ini
%else
    /sbin/service php7-fpm stop > /dev/null 2>&1
    rm -f %{php_path}/etc/php.d/50-beast.ini
%endif
fi

# rpm卸载后执行的脚本
%postun
if [ $1 -eq 0 ]; then
%if %use_systemd
    /usr/bin/systemctl start php7-fpm.service >/dev/null 2>&1 ||:
%else
    /sbin/service php7-fpm start > /dev/null 2>&1
%endif
fi


%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{php_extdir}/beast.so

%changelog
* Tue Dec 25 2018 xiao.li <371583076@qq.com> 1.0.0
- Initial version

