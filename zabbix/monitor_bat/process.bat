@echo off
set process_name=%1%
set filename=%2%
wmic path win32_process where name="%process_name%" get Name,commandline 2>nul|find /i "%filename%" 2>nul 1>nul && echo 1 || echo 0
