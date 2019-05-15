
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
Source: V1.0.39.tar.gz

%description
libfastcommon

%prep
%setup -q
sudo rm -rf $RPM_BUILD_DIR/libfastcommon-1.0.39
tar -xvf $RPM_SOURCE_DIR/V1.0.39.tar.gz -C $RPM_BUILD_DIR
#zcat $RPM_SOURCE_DIR/V1.0.39.tar.gz | tar -xvf -


%build
cd $RPM_BUILD_DIR/libfastcommon-1.0.39
./make.sh clean && ./make.sh
./make.sh install

%install
sudo mkdir -p %{buildroot}/usr/include
sudo mkdir -p %{buildroot}/usr/lib64
sudo mkdir -p %{buildroot}/usr/lib
sudo cp -rfp /usr/lib64/libfastcommon.so %{buildroot}/usr/lib64
sudo cp -rfp /usr/lib/libfastcommon.so %{buildroot}/usr/lib
sudo cp -rfp /usr/include/fastcommon  %{buildroot}/usr/include

%post

%preun

%postun

%clean

%files
/usr/lib64/libfastcommon.so*
/usr/lib/libfastcommon.so*
/usr/include/fastcommon/*

%changelog
