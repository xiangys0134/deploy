@echo off
set hostname=%1%
C:\Windows\System32\PING.EXE %hostname% -w 3 -n 2 1>nul 2>nul && echo 1 || echo 0
