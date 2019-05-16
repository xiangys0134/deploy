Name: xc-front-xone		
Release:	1%{?dist}
Summary:xunce xone web service
Version:master.13

Group: Applications		
License: BSD
URL: http://www.xuncetech.com/
Source0: xc-front-xone

BuildRequires: nodejs	
Requires: nginx

%description
xc xc-front-xone service

%build
cd $RPM_BUILD_DIR/xc-front-xone
sudo npm install
sudo npm run build 
if [ $? -ne 0 ]; then
    echo "npm error"
    exit 6
fi

%install
sudo rm -rf %{buildroot}/data/xc-front-xone
sudo mkdir -p %{buildroot}/data/xc-front-xone
sudo chown -R jenkins. %{buildroot}
cp -r $RPM_BUILD_DIR/xc-front-xone/dist/. %{buildroot}/data/xc-front-xone
%{__install} -p -D -m 0644 /data/jenkins/build/xc-front-xone/xc-front-xone.conf %{buildroot}/etc/nginx/conf.d/xc-front-xone.conf
 
%post
localip=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}'|head -1)
sudo sed -i "s/localhost/${localip}/g" /etc/nginx/conf.d/xc-front-xone.conf

%files
%doc
/data/xc-front-xone
/etc/nginx/conf.d/xc-front-xone.conf


%changelog

