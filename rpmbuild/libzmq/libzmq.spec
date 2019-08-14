%define libzmq_version 4.2.1
Name:	libzmq	
Version:	%{libzmq_version}
Release:	1%{?dist}
Summary:	ZeroMQ core engine in C++, implements ZMTP/3.1

Group:		Development/Libraries
License:	BSD
URL:		https://github.com/xiangys0134
#Source0:	https://github.com/zeromq/libzmq/archive/v4.2.1.tar.gz
#Source0:	https://soft.g6p.cn/deploy/source/libzmq-4.2.1.tar.gz
Source0:	v4.2.1.tar.gz

BuildRequires:	libtool >= 2.4.2,make >= 3.28 
#BuildRequires:	make,libtool 
#Requires:	

%description
libzmq

%prep
#%autosetup -n libzmq-%{libzmq_version}
%setup -q
#cd $RPM_BUILD_ROOT/libzmq-%{libzmq_version}
./autogen.sh

%build
#%configure
#cd $RPM_BUILD_ROOT/libzmq-%{libzmq_version}
./configure --prefix=/usr
#make %{?_smp_mflags}


%install
make install DESTDIR=%{buildroot}


%files
%doc
/usr/bin/curve_keygen
/usr/include/zmq.h
/usr/include/zmq_utils.h
/usr/lib/libzmq.a
/usr/lib/libzmq.la
/usr/lib/libzmq.so
/usr/lib/libzmq.so.5
/usr/lib/libzmq.so.5.1.1
/usr/lib/pkgconfig/libzmq.pc



%changelog
