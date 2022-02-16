@echo off  & setlocal ENABLEEXTENSIONS 

:: ---------- ������ ---------- 

:: ���ݷ��õ�·������ \ 
set BACKUP_PATH=E:\Backup\ 

:: Ҫ���ݵ����ݿ����ƣ�����ÿո�ָ�,���ֱ�������Ƚ����ݿ�ͨ���ű���ȡ���������ݿ������ô���Ҫ�ع�--2019.02.03
set DATABASES=c1 c2 c3 

:: MySQL �û��� 
set USERNAME=root 

:: MySQL ���� 
set PASSWORD=123456 

:: MySQL Bin Ŀ¼���� \ 
:: �������ֱ��ʹ�� mysqldump����װʱ��� MySQL Bin Ŀ¼���˻������������˴����ռ��� 
set MYSQL=E:\mysql-5.7.13-winx64\bin\

:: WinRAR �Դ������й��ߵĿ�ִ���ļ�·�������ļ���ע���� Dos ���ļ�����д��ʽ 
set WINRAR=C:\Program Files (x86)\WinRAR\WinRAR.exe

:: ---------- ���������޸� ---------- 

set YEAR=%date:~0,4% 
set MONTH=%date:~5,2% 
set DAY=%date:~8,2% 
:: ����� dos ������ time ���صĲ��� 24 Сʱ�ƣ�û�� 0 ��䣩���������޸Ĵ˴� 
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