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
Source: fastdfs-5.11.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n) 

Requires: %__cp %__mv %__chmod %__grep %__mkdir %__install %__id
BuildRequires: libfastcommon-devel >= 1.0.36

%description
This package provides tracker & storage of fastdfs
commit version: %{CommitVersion}


%prep
%setup -q

%build
./make.sh

%install
rm -rf %{buildroot}
DESTDIR=$RPM_BUILD_ROOT ./make.sh install

%postun

%clean

%files

%files
/usr/bin/fdfs_trackerd
/usr/bin/fdfs_storaged
/usr/bin/restart.sh
/usr/bin/stop.sh
/etc/init.d/*
/etc/fdfs/tracker.conf.sample
/etc/fdfs/storage.conf.sample
/etc/fdfs/storage_ids.conf.sample

/usr/lib64/libfdfsclient*
/usr/lib/libfdfsclient*
/etc/fdfs/client.conf.sample

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
* Mon Jun 23 2014  Zaixue Liao <liaozaixue@yongche.com>
- first RPM release (1.0)
