@echo off

::��װIIS
echo ��װIIS8
powershell install-windowsfeature web-server

::��װtelnet-client
echo ��װtelnet-client
powershell install-windowsfeature Telnet-Client

::��װNET-Framework4.6
echo ��װNET-Framework4.6
cd /d %~pd0\Source
start /wait NDP46-KB3045557-x86-x64-AllOS-ENU.exe /install /quiet /norestart

::��װc++
cd /d %~pd0\Source\c++
echo ��װc++
start /wait vcredist2013_x64.exe /install /quiet /norestart
start /wait vcredist2013_x86.exe /install /quiet /norestart
Rem start /wait vcredist_x64_c++2008.exe /i /q
start /wait vcredist_x86.exe /install /quiet /norestart
start /wait vcredist_x86_2010.exe /install /quiet /norestart
Rem start /wait vcredist_x86_c++2008.exe /install /quiet /norestart
start /wait vc_redist.x64.exe /install /quiet /norestart


echo �����û�������������
wmic Path win32_useraccount where name="Administrator" Set PasswordExpires="FALSE"
echo ��װWinRAR.....................
cd /d %~pd0\Source
start /wait winrar_x64_501sc.exe /S
echo ��װNotepad.....................
cd /d %~pd0\Source
start /wait npp.7.5.6.Installer.x64.exe /S

echo ��ʼ�����...
pause