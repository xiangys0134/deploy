%define lua_iconv_version 7
Name:	lua-iconv	
Version:	%{lua_iconv_version}
Release:	1%{?dist}
Summary:	lua-iconv 

Group:		Development/Libraries
License:	BSD
URL:		https://github.com/xiangys0134
#Source0:	https://github.com/downloads/ittner/lua-iconv/lua-iconv-7.tar.gz
Source0:	lua-iconv-7.tar.gz

BuildRequires:	luarocks >= 2.3.0,lua-devel >= 5.1.4
#Requires:	

%description
lua-iconv

%prep
%setup -q

%build
luarocks install lua-iconv

%install
make install DESTDIR=%{buildroot}


%files
%doc
/usr/lib64/lua/5.1/iconv.so


%changelog

