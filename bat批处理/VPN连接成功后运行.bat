::VPN连接成功后运行
@echo off
for /f "tokens=2 delims=:" %%i in ('ipconfig^|findstr /i 192.168.*.1') do set gateway=%%i
set gateway=%gateway: =%
route delete 192.168.0.0
route add 192.168.0.0 mask 255.255.0.0 %gateway%
route add 0.0.0.0 mask 0.0.0.0 %gateway%
exit