%define XC_OSP_FRONT_VERSION 100.100.1
%define XC_OSP_FRONT_NAME baseModule
Name:     %{XC_OSP_FRONT_NAME}
Version:	%{XC_OSP_FRONT_VERSION}
Release:	1%{?dist}
Summary:xunce baseModule

Group:Applications
License:BSD
URL:http://www.xuncetech.com/
Source0:xc-osp/

BuildRequires: nodejs >= 8.10

%description
xunce osp baseModule

%prep

%build
source ~/.bashrc && source /etc/profile
yarn
npm run build

%install
%{__mkdir_p} $RPM_BUILD_ROOT/data/www/baseModule/build
%{__cp} -ar  %_builddir/build/* $RPM_BUILD_ROOT/data/www/baseModule/build/

%post
echo -e "\033[32m 请检查nginx配置文件是否正确 \033[0m"
echo -e "\033[32m [安装完成] 程序主目录为/data/www/baseModule/build \033[0m"

%files
%doc
/data/www/baseModule/build

%changelog
