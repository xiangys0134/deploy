@echo off
@color 0a
rem ===================================控制面板========================================================================
setlocal enableextensions
mode con lines=25 cols=120
prompt -$g
title  XXXX有限责任公司  - Windows 2012服务器系统初始化 - 控制面板 -by xxx
goto menu
:menu
cls
@ECHO                  ┏--------------------------------------------------------------------------┓
@ECHO                  ┃                                                                          ┃
@ECHO                  ┃       XXXX有限责任公司 - Windows服务器系统初始化  -   控制面板           ┃
@ECHO                  ┃                                                                          ┃
@ECHO                  ┃           1.服务器系统初始化           2.非选择项                        ┃
@ECHO                  ┃                                                                          ┃
@ECHO                  ┃                                                                          ┃
@ECHO                  ┃                                                                          ┃
@ECHO                  ┃                                                                          ┃
@ECHO                  ┃                                                                          ┃
@ECHO                  ┗--------------------------------------------------------------------------┛
set /p input=-^> 请选择: 
if "%input%"== "1" goto init_system
::if "%input%"== "2" goto install_TBMonitor
rem  ===================================自动配置服务器环境========================================================================
:init_system
cls
@ECHO ┏-----------------------------------------------------------------------------------┓
@ECHO ┃                                                                                   ┃
@ECHO ┃    自动配置服务器环境:(1.系统桌面设置; 2.关闭自动更新; 3.禁止windows错误报告      ┃
@ECHO ┃    ; 4.删除默认共享 ; 5.禁止关机事件跟踪 ; 6.关闭UAC; 7.同步系统时间；            ┃
@ECHO ┃                                                                                   ┃
@ECHO ┗-----------------------------------------------------------------------------------┛
timeout 30
echo 添加桌面图标
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t reg_dword /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t reg_dword /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t reg_dword /d 0 /f
echo 在登录时不自动显示服务器管理器
reg add "HKEY_CURRENT_USER\Software\Microsoft\ServerManager" /v "DoNotOpenServerManagerAtLogon" /t reg_dword /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Oobe" /v "DoNotOpenInitialConfigurationTasksAtLogon" /t reg_dword /d 1 /f
echo 关闭Windows 自动更新
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "ScheduledInstallDay" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "ScheduledInstallTime" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t reg_dword /d 1 /f 
echo 设置TCP连接延迟等待时间 TcpTimedWaitDelay:这是设定TCP/IP 可释放已关闭连接并重用其资源前，必须经过的时间。关闭和释放之间的此时间间隔通称 TIME_WAIT状态或两倍最大段生命周期（2MSL）状态。
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v TcpTimedWaitDelay /t reg_dword /d 30 /f
echo 最大TCP使用端口 MaxUserPort：TCP客户端和服务器连接时，客户端必须分配一个动态端口，默认情况下这个动态端口的分配范围为 1024-5000，也就是说默认情况下，客户端最多可以同时发起3977个Socket连接。通过修改调整这个动态端口的范围，可以提高系统的数据吞吐率
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v MaxUserPort /t reg_dword /d 65534 /f
echo 保持连接时间 KeepAliveTime：Windows默认情况下不发送保持活动数据包，但某些TCP包中可能请求保持活动的数据包。保持连接可以被攻击者利用建立大量的连接造成服务器拒绝服务。降低这个参数值有助于系统更快速地断开非活动会话。
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v KeepAliveTime /t reg_dword /d 1800000 /f
echo 禁止Windows错误报告........
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PCHealth\ErrorReporting" /v DoReport /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PCHealth\ErrorReporting" /v ShowUI /t reg_dword /d 0 /f
echo 删除默认共享........................
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v AutoShareWks /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" /v AutoShareServer /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v restrictanonymous /t reg_dword /d 1 /f
sc stop lanmanserver
echo 关闭UAC.....................
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t reg_dword /d 0 /f
Rem 关闭IE ESC
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v "IsInstalled" /t reg_dword /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" /v "IsInstalled" /t reg_dword /d 0 /f
echo 同步intelnet时间.....................
cd /d %~pd0\Source
start SetDateTime.exe
echo 本机系统时间设置完成！

rem echo Rem 安装NET-Framework3.5 .....................
PowerShell Install-WindowsFeature Net-Framework-Core

echo 安装 Telnet 客户端
PowerShell Install-WindowsFeature Telnet-Client
echo 安装  桌面体验
PowerShell Install-WindowsFeature Desktop-Experience

rem echo 安装NET-Framework4.6.....................
rem cd /d %~pd0\Source
rem start /wait NDP462-KB3151800-x86-x64-AllOS-ENU.exe /lang:CHS /q /norestart 
rem echo 安装powershell 3.0.....................
rem cd /d %~pd0\Source
rem start /wait wusa Windows6.1-KB2506143-x64.msu /quiet /norestart

C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -force
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -force
::echo 安装c++依赖库
::cd /d %~pd0\Source\c++

::start /wait vcredist2013_x64.exe /install /quiet /norestart
::start /wait vcredist2013_x86.exe /install /quiet /norestart
::Rem start /wait vcredist_x64_c++2008.exe /i /q
::start /wait vcredist_x86.exe /install /quiet /norestart
::start /wait vcredist_x86_2010.exe /install /quiet /norestart
::Rem start /wait vcredist_x86_c++2008.exe /install /quiet /norestart
::start /wait vc_redist.x64.exe /install /quiet /norestart
::start /wait vc_redist.x86.exe /install /quiet /norestart

echo 设置用户密码永不过期
wmic Path win32_useraccount where name="Administrator" Set PasswordExpires="FALSE"
echo 安装WinRAR.....................
cd /d %~pd0\Source
start /wait winrar_x64_501sc.exe /S
echo 安装Notepad.....................
cd /d %~pd0\Source
start /wait npp.7.5.6.Installer.x64.exe /S
echo 安装git.....................
cd /d %~pd0\Source
start /wait Git-2.18.0-64-bit.exe /silent
echo 创建脚本目录
xcopy /s /q /i /y %~pd0\script c:\script
echo 初始化完毕，一分钟倒计时重启
timeout 60
shutdown -r -t 0

::install_TBMonitor
::echo 正在安装TBMonitor
::powershell C:\script\TBMonitor.ps1 -setup
::echo TBMonitor安装成功
::pause
::goto menu