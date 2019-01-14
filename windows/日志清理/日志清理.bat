@echo off
set dir_log=C:\release\tb\logs
set date_time=%date% %time%
set delete_log=delete.log

::echo %dir_log%

forfiles   /p %dir_log% /S /M *.log /d -3 /c "cmd /c echo deleting @file ... && del /f @path"

cd /d %~dp0
echo %date_time% 日志清理 >>%delete_log%