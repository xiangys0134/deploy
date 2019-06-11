%define LibFastcommonDevel  libfastcommon-devel
%define LibFastcommonDebuginfo  libfastcommon-debuginfo
%define CommitVersion %(echo $COMMIT_VERSION)

Name: libfastcommon
Version: 1.0.39
Release: 1%{?dist}
Summary: c common functions library extracted from my open source projects FastDFS
License: LGPL
Group: Arch/Tech
URL:  http://github.com/happyfish100/libfastcommon/
Source: V%{version}.tar.gz

#BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n) 

#Requires: 
#BuildRequires: 
#BuildRequires: perl %{_includedir}/linux/if.h gettext
#Requires: %__cp %__mv %__chmod %__grep %__mkdir %__install %__id

%description
c common functions library extracted from my open source projects FastDFS.
this library is very simple and stable. functions including: string, logger,
chain, hash, socket, ini file reader, base64 encode / decode,
url encode / decode, fasttimer etc. 
commit version: %{CommitVersion}


%prep
%setup -q

%build
#./make.sh clean && ./make.sh
cd $RPM_BUILD_DIR/libfastcommon-1.0.39
sudo ./make.sh
sudo ./make.sh install

%install
#rm -rf %{buildroot}
#DESTDIR=$RPM_BUILD_ROOT ./make.sh install
#INSTALL_ROOT=$RPM_BUILD_ROOT ./make.sh install
%{__mkdir} -p %{buildroot}/usr/include/fastcommon
%{__mkdir} -p %{buildroot}/usr/lib
%{__mkdir} -p %{buildroot}/usr/lib64
mv /usr/lib/libfastcommon.so %{buildroot}/usr/lib/
mv /usr/lib64/libfastcommon.so %{buildroot}/usr/lib64/
mv /usr/include/fastcommon/* %{buildroot}/usr/include/fastcommon/ 


%post

%preun

%postun

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
/usr/lib64/libfastcommon.so*
/usr/lib/libfastcommon.so*
/usr/include/fastcommon*

#%files devel
#%defattr(-,root,root,-)
#/usr/include/fastcommon*

%changelog
* Mon Jun 23 2014  Zaixue Liao <liaozaixue@yongche.com>
- first RPM release (1.0)
