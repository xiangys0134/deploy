@echo off
@color 0a
rem ===================================�������========================================================================
setlocal enableextensions
mode con lines=25 cols=120
prompt -$g
title  XXXX�������ι�˾  - Windows 2012������ϵͳ��ʼ�� - ������� -by xxx
goto menu
:menu
cls
@ECHO                  ��--------------------------------------------------------------------------��
@ECHO                  ��                                                                          ��
@ECHO                  ��       XXXX�������ι�˾ - Windows������ϵͳ��ʼ��  -   �������           ��
@ECHO                  ��                                                                          ��
@ECHO                  ��           1.������ϵͳ��ʼ��           2.��ѡ����                        ��
@ECHO                  ��                                                                          ��
@ECHO                  ��                                                                          ��
@ECHO                  ��                                                                          ��
@ECHO                  ��                                                                          ��
@ECHO                  ��                                                                          ��
@ECHO                  ��--------------------------------------------------------------------------��
set /p input=-^> ��ѡ��: 
if "%input%"== "1" goto init_system
::if "%input%"== "2" goto install_TBMonitor
rem  ===================================�Զ����÷���������========================================================================
:init_system
cls
@ECHO ��-----------------------------------------------------------------------------------��
@ECHO ��                                                                                   ��
@ECHO ��    �Զ����÷���������:(1.ϵͳ��������; 2.�ر��Զ�����; 3.��ֹwindows���󱨸�      ��
@ECHO ��    ; 4.ɾ��Ĭ�Ϲ��� ; 5.��ֹ�ػ��¼����� ; 6.�ر�UAC; 7.ͬ��ϵͳʱ�䣻            ��
@ECHO ��                                                                                   ��
@ECHO ��-----------------------------------------------------------------------------------��
timeout 30
echo �������ͼ��
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t reg_dword /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t reg_dword /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t reg_dword /d 0 /f
echo �ڵ�¼ʱ���Զ���ʾ������������
reg add "HKEY_CURRENT_USER\Software\Microsoft\ServerManager" /v "DoNotOpenServerManagerAtLogon" /t reg_dword /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Oobe" /v "DoNotOpenInitialConfigurationTasksAtLogon" /t reg_dword /d 1 /f
echo �ر�Windows �Զ�����
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "ScheduledInstallDay" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "ScheduledInstallTime" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t reg_dword /d 1 /f 
echo ����TCP�����ӳٵȴ�ʱ�� TcpTimedWaitDelay:�����趨TCP/IP ���ͷ��ѹر����Ӳ���������Դǰ�����뾭����ʱ�䡣�رպ��ͷ�֮��Ĵ�ʱ����ͨ�� TIME_WAIT״̬�����������������ڣ�2MSL��״̬��
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v TcpTimedWaitDelay /t reg_dword /d 30 /f
echo ���TCPʹ�ö˿� MaxUserPort��TCP�ͻ��˺ͷ���������ʱ���ͻ��˱������һ����̬�˿ڣ�Ĭ������������̬�˿ڵķ��䷶ΧΪ 1024-5000��Ҳ����˵Ĭ������£��ͻ���������ͬʱ����3977��Socket���ӡ�ͨ���޸ĵ��������̬�˿ڵķ�Χ���������ϵͳ������������
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v MaxUserPort /t reg_dword /d 65534 /f
echo ��������ʱ�� KeepAliveTime��WindowsĬ������²����ͱ��ֻ���ݰ�����ĳЩTCP���п������󱣳ֻ�����ݰ����������ӿ��Ա����������ý���������������ɷ������ܾ����񡣽����������ֵ������ϵͳ�����ٵضϿ��ǻ�Ự��
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v KeepAliveTime /t reg_dword /d 1800000 /f
echo ��ֹWindows���󱨸�........
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PCHealth\ErrorReporting" /v DoReport /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PCHealth\ErrorReporting" /v ShowUI /t reg_dword /d 0 /f
echo ɾ��Ĭ�Ϲ���........................
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v AutoShareWks /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v AutoShareServer /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v restrictanonymous /t reg_dword /d 1 /f
sc stop lanmanserver
echo �ر�UAC.....................
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t reg_dword /d 0 /f
Rem �ر�IE ESC
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v "IsInstalled" /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" /v "IsInstalled" /t reg_dword /d 0 /f
echo ͬ��intelnetʱ��.....................
cd /d %~pd0\Source
start SetDateTime.exe
echo ����ϵͳʱ��������ɣ�

rem echo Rem ��װNET-Framework3.5 .....................
PowerShell Install-WindowsFeature Net-Framework-Core

echo ��װ Telnet �ͻ���
PowerShell Install-WindowsFeature Telnet-Client
echo ��װ  ��������
PowerShell Install-WindowsFeature Desktop-Experience

rem echo ��װNET-Framework4.6.....................
rem cd /d %~pd0\Source
rem start /wait NDP462-KB3151800-x86-x64-AllOS-ENU.exe /lang:CHS /q /norestart 
rem echo ��װpowershell 3.0.....................
rem cd /d %~pd0\Source
rem start /wait wusa Windows6.1-KB2506143-x64.msu /quiet /norestart

C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -force
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -force
::echo ��װc++������
::cd /d %~pd0\Source\c++

::start /wait vcredist2013_x64.exe /install /quiet /norestart
::start /wait vcredist2013_x86.exe /install /quiet /norestart
::Rem start /wait vcredist_x64_c++2008.exe /i /q
::start /wait vcredist_x86.exe /install /quiet /norestart
::start /wait vcredist_x86_2010.exe /install /quiet /norestart
::Rem start /wait vcredist_x86_c++2008.exe /install /quiet /norestart
::start /wait vc_redist.x64.exe /install /quiet /norestart
::start /wait vc_redist.x86.exe /install /quiet /norestart

echo �����û�������������
wmic Path win32_useraccount where name="Administrator" Set PasswordExpires="FALSE"
echo ��װWinRAR.....................
cd /d %~pd0\Source
start /wait winrar_x64_501sc.exe /S
echo ��װNotepad.....................
cd /d %~pd0\Source
start /wait npp.7.5.6.Installer.x64.exe /S
echo ��װgit.....................
cd /d %~pd0\Source
start /wait Git-2.18.0-64-bit.exe /silent
echo �����ű�Ŀ¼
xcopy /s /q /i /y %~pd0\script c:\script
echo ��ʼ����ϣ�һ���ӵ���ʱ����
timeout 60
shutdown -r -t 0

::install_TBMonitor
::echo ���ڰ�װTBMonitor
::powershell C:\script\TBMonitor.ps1 -setup
::echo TBMonitor��װ�ɹ�
::pause
::goto menu