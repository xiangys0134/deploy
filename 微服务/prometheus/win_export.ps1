$String1='download windows_exporter-0.16.0-amd64.msi...' 
$String2='install windows_exporter-0.16.0-amd64.msi...' 
$String3='The installation is complete.' 
$String4='Windows Defender Allow Port 9182.' 



$client = new-object System.Net.WebClient
$client.DownloadFile('https://github.com/prometheus-community/windows_exporter/releases/download/v0.16.0/windows_exporter-0.16.0-amd64.msi','C:\windows_exporter-0.16.0-amd64.msi')
$String1
Sleep 3


Invoke-CimMethod -ClassName Win32_Product -MethodName Install -Arguments @{PackageLocation='C:\windows_exporter-0.16.0-amd64.msi'}
$String2
Sleep 3

Get-CimInstance -Class Win32_Product|Where-Object Name -eq "windows_exporter"
$String3
Sleep 3

New-NetFirewallRule -DisplayName “Allow Inbound export” -Direction Inbound -Program %SystemRoot%\System32\tlntsvr.exe -RemoteAddress LocalSubnet -Action Allow –Protocol TCP –LocalPort 9182
$String4
Sleep 30
exit