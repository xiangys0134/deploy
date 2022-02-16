@echo off  & setlocal ENABLEEXTENSIONS 

:: ---------- 配置项 ---------- 

:: 备份放置的路径，加 \ 
set BACKUP_PATH=E:\Backup\ 

:: 要备份的数据库名称，多个用空格分隔,这种备份最好先将数据库通过脚本获取到具体数据库名，该处需要重构--2019.02.03
set DATABASES=c1 c2 c3 

:: MySQL 用户名 
set USERNAME=root 

:: MySQL 密码 
set PASSWORD=123456 

:: MySQL Bin 目录，加 \ 
:: 如果可以直接使用 mysqldump（安装时添加 MySQL Bin 目录到了环境变量），此处留空即可 
set MYSQL=E:\mysql-5.7.13-winx64\bin\

:: WinRAR 自带命令行工具的可执行文件路径，长文件名注意用 Dos 长文件名书写方式 
set WINRAR=C:\Program Files (x86)\WinRAR\WinRAR.exe

:: ---------- 以下请勿修改 ---------- 

set YEAR=%date:~0,4% 
set MONTH=%date:~5,2% 
set DAY=%date:~8,2% 
:: 如果在 dos 下输入 time 返回的不是 24 小时制（没有 0 填充），请自行修改此处 
set HOUR=%time:~0,2% 
set MINUTE=%time:~3,2% 
set SECOND=%time:~6,2% 

::set DIR=%BACKUP_PATH%%YEAR%\%MONTH%\%DAY%\
set DIR=%BACKUP_PATH%
::set ADDON=%YEAR%%MONTH%%DAY%%HOUR%%MINUTE%%SECOND%
set ADDON=%date:~0,4%%date:~5,2%%date:~8,2%

:: create dir 
if not exist %DIR% ( 
mkdir %DIR% 2>nul 
) 
if not exist %DIR% ( 
echo Backup path: %DIR% not exists, create dir failed. 
goto exit 
) 
cd /d %DIR% 

:: backup 
echo Start dump databases... 

%MYSQL%mysqldump -u%USERNAME% -p%PASSWORD% -F -B %DATABASES%  --single-transaction --master-data=2 -e  > %ADDON%.sql 2>nul 
::for %%D in (%DATABASES%) do ( 
::echo Dumping database %%D ... 
::%MYSQL%mysqldump -u%USERNAME% -p%PASSWORD% -F -B %DATABASES%  --single-transaction --master-data=2 -e %%D > %%D.%ADDON%.sql 2>nul 
:: winrar 
::if exist %WINRAR% ( 
::%WINRAR% a -k -r -s -m1 -ep1 %ADDON%.rar %ADDON%.sql 2>nul 
::) 
::)
"C:\Program Files (x86)\WinRAR\WinRAR.exe"  a  -r  %ADDON%.rar %ADDON%.sql 
timeout /t 600 /nobreak > null
del /F /S /Q %ADDON%.sql 
forfiles   /p "E:\Backup" /S /M *.rar /d -30 /c "cmd /c echo deleting @file ... && del /f @path"
::echo Done 

:exit 