%define FastDFS    fastdfs
%define FDFSServer fastdfs-server
%define FDFSClient libfdfsclient
%define FDFSClientDevel libfdfsclient-devel
%define FDFSTool   fastdfs-tool
%define FDFSVersion 5.11
%define CommitVersion %(echo $COMMIT_VERSION)

Name: %{FastDFS}
Version: %{FDFSVersion}
Release: 1%{?dist}
Summary: FastDFS server and client
License: GPL
Group: Arch/Tech
URL: 	http://perso.orange.fr/sebastien.godard/
Source: V%{version}.tar.gz

#BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n) 

Requires: libfastcommon >= 1.0.36
BuildRequires: libfastcommon >= 1.0.36

%description
This package provides tracker & storage of fastdfs
commit version: %{CommitVersion}


%prep
%setup -q

%build
sudo ./make.sh
sudo ./make.sh install


%install
rm -rf %{buildroot}
%{__mkdir} -p %{buildroot}/usr/bin
%{__mkdir} -p %{buildroot}/usr/lib64
%{__mkdir} -p %{buildroot}/etc/init.d
%{__mkdir} -p %{buildroot}/usr/lib

%{__install} -p -D -m 0755 /usr/bin/restart.sh %{buildroot}/usr/bin/restart.sh
%{__install} -p -D -m 0755 /usr/bin/stop.sh %{buildroot}/usr/bin/stop.sh

%{__install} -p -D -m 0755 /usr/bin/fdfs_append_file %{buildroot}/usr/bin/fdfs_append_file
%{__install} -p -D -m 0755 /usr/bin/fdfs_appender_test %{buildroot}/usr/bin/fdfs_appender_test
%{__install} -p -D -m 0755 /usr/bin/fdfs_appender_test1 %{buildroot}/usr/bin/fdfs_appender_test1
%{__install} -p -D -m 0755 /usr/bin/fdfs_crc32 %{buildroot}/usr/bin/fdfs_crc32
%{__install} -p -D -m 0755 /usr/bin/fdfs_delete_file %{buildroot}/usr/bin/fdfs_delete_file
%{__install} -p -D -m 0755 /usr/bin/fdfs_download_file %{buildroot}/usr/bin/fdfs_download_file
%{__install} -p -D -m 0755 /usr/bin/fdfs_file_info %{buildroot}/usr/bin/fdfs_file_info
%{__install} -p -D -m 0755 /usr/bin/fdfs_monitor %{buildroot}/usr/bin/fdfs_monitor
%{__install} -p -D -m 0755 /usr/bin/fdfs_storaged %{buildroot}/usr/bin/fdfs_storaged
%{__install} -p -D -m 0755 /usr/bin/fdfs_test %{buildroot}/usr/bin/fdfs_test
%{__install} -p -D -m 0755 /usr/bin/fdfs_test1 %{buildroot}/usr/bin/fdfs_test1
%{__install} -p -D -m 0755 /usr/bin/fdfs_trackerd %{buildroot}/usr/bin/fdfs_trackerd
%{__install} -p -D -m 0755 /usr/bin/fdfs_upload_appender %{buildroot}/usr/bin/fdfs_upload_appender
%{__install} -p -D -m 0755 /usr/bin/fdfs_upload_file %{buildroot}/usr/bin/fdfs_upload_file
%{__install} -p -D -m 0755 /etc/init.d/fdfs_storaged %{buildroot}/etc/init.d/fdfs_storaged
%{__install} -p -D -m 0755 /etc/init.d/fdfs_trackerd %{buildroot}/etc/init.d/fdfs_trackerd
%{__install} -p -D -m 0755 /usr/lib/libfdfsclient.so %{buildroot}/usr/lib/libfdfsclient.so
%{__install} -p -D -m 0755 /usr/lib64/libfdfsclient.so %{buildroot}/usr/lib64/libfdfsclient.so

%{__mkdir} -p %{buildroot}/usr/include/fastdfs
mv /usr/include/fastdfs/* %{buildroot}/usr/include/fastdfs/
mv /etc/fdfs %{buildroot}/etc/


%postun

%clean


%files 
%defattr(-,root,root,-)
/usr/bin/fdfs_trackerd
/usr/bin/fdfs_storaged
/usr/bin/restart.sh
/usr/bin/stop.sh
/etc/init.d/*
/etc/fdfs/tracker.conf.sample
/etc/fdfs/storage.conf.sample
/etc/fdfs/storage_ids.conf.sample
/etc/fdfs/client.conf.sample
/usr/lib64/libfdfsclient*
/usr/lib/libfdfsclient*
/usr/include/fastdfs/*
/usr/bin/fdfs_monitor
/usr/bin/fdfs_test
/usr/bin/fdfs_test1
/usr/bin/fdfs_crc32
/usr/bin/fdfs_upload_file
/usr/bin/fdfs_download_file
/usr/bin/fdfs_delete_file
/usr/bin/fdfs_file_info
/usr/bin/fdfs_appender_test
/usr/bin/fdfs_appender_test1
/usr/bin/fdfs_append_file
/usr/bin/fdfs_upload_appender

%changelog
