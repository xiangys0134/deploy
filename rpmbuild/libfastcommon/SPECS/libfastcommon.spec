Name:	libfastcommon 
Version:	1.0.39
Release:	1%{?dist}
Summary:	libfastcommon

Group:	Applications
License:	BSD
URL:	https://github.com/xiangys0134
Source0:	V%{version}.tar.gz

BuildRequires:	make gcc
#Requires: 

%description
libfastcommon

%prep
%setup
#sudo rm -rf $RPM_BUILD_DIR/libfastcommon-1.0.39
#zcat $RPM_SOURCE_DIR/V1.0.39.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/libfastcommon-1.0.39
sudo ./make.sh
sudo ./make.sh install
if [ $? -ne 0 ]; then
    echo "make install failed"
    exit 4
fi

%install
%{__install} -p -D -m 0644 /usr/lib/libfastcommon.so %{buildroot}/usr/lib/libfastcommon.so
%{__install} -p -D -m 0644 /usr/lib64/libfastcommon.so %{buildroot}/usr/lib64/libfastcommon.so

%files
%doc
/usr/lib/libfastcommon.so
/usr/lib64/libfastcommon.so


%changelog
