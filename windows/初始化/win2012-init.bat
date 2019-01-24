@echo off

::安装IIS
echo 安装IIS8
powershell install-windowsfeature web-server

::安装telnet-client
echo 安装telnet-client
powershell install-windowsfeature Telnet-Client

::安装NET-Framework4.6
echo 安装NET-Framework4.6
cd /d %~pd0\Source
start /wait NDP46-KB3045557-x86-x64-AllOS-ENU.exe /install /quiet /norestart

::安装c++
cd /d %~pd0\Source\c++
echo 安装c++
start /wait vcredist2013_x64.exe /install /quiet /norestart
start /wait vcredist2013_x86.exe /install /quiet /norestart
Rem start /wait vcredist_x64_c++2008.exe /i /q
start /wait vcredist_x86.exe /install /quiet /norestart
start /wait vcredist_x86_2010.exe /install /quiet /norestart
Rem start /wait vcredist_x86_c++2008.exe /install /quiet /norestart
start /wait vc_redist.x64.exe /install /quiet /norestart


echo 设置用户密码永不过期
wmic Path win32_useraccount where name="Administrator" Set PasswordExpires="FALSE"
echo 安装WinRAR.....................
cd /d %~pd0\Source
start /wait winrar_x64_501sc.exe /S
echo 安装Notepad.....................
cd /d %~pd0\Source
start /wait npp.7.5.6.Installer.x64.exe /S

echo 初始化完成...
pause