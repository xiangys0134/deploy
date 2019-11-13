@ECHO OFF
TITLE Windows 全版本系统激活
ECHO 检测 操作系统版本...
SET RQR=REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ProductName"

%RQR% | findstr /IC:"Vista" &&SET VER=Vista
%RQR% | findstr /IC:"7" &&SET VER=Win7
%RQR% | findstr /IC:"8" &&SET VER=Win8
%RQR% | findstr /IC:"8.1" &&SET VER=Win8.1
%RQR% | findstr /IC:"10" &&SET VER=Win10
%RQR% | findstr /IC:"2008" &&SET VER=2008
%RQR% | findstr /IC:"2008 R2" &&SET VER=2008R2
%RQR% | findstr /IC:"2012" &&SET VER=2012
%RQR% | findstr /IC:"2012 R2" &&SET VER=2012R2
%RQR% | findstr /IC:"2016" &&SET VER=2016
%RQR% | findstr /IC:"2019" &&SET VER=2019

goto %VER%

:Vista
ECHO 操作系统为 Windows Vista 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Business" &&SET SLPKEY=YFKBB-PQJJV-G996G-VWGXY-2V3X8
%RQR% | findstr /IC:"Business N" &&SET SLPKEY=HMBQG-8H2RH-C77VX-27R82-VMQBT
%RQR% | findstr /IC:"Enterprise" &&SET SLPKEY=VKK3X-68KWM-X2YGT-QR4M6-4BWMV
%RQR% | findstr /IC:"Enterprise N" &&SET SLPKEY=VTC42-BM838-43QHV-84HX6-XJXKV
goto OEMINS

:Win7
ECHO 操作系统为 Windows 7 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Professional" &&SET SLPKEY=FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4
%RQR% | findstr /IC:"Professional N" &&SET SLPKEY=MRPKT-YTG23-K7D7T-X2JMM-QY7MG
%RQR% | findstr /IC:"Professional E" &&SET SLPKEY=W82YF-2Q76Y-63HXB-FGJG9-GF7QX
%RQR% | findstr /IC:"Enterprise" &&SET SLPKEY=33PXH-7Y6KF-2VJC9-XBBR8-HVTHH
%RQR% | findstr /IC:"Enterprise N" &&SET SLPKEY=YDRBP-3D83W-TY26F-D46B2-XCKRJ
%RQR% | findstr /IC:"Enterprise E" &&SET SLPKEY=C29WB-22CC8-VJ326-GHFJW-H9DH4
goto OEMINS

:Win8
ECHO 操作系统为 Windows 8 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Professional" &&SET SLPKEY=NG4HW-VH26C-733KW-K6F98-J8CK4
%RQR% | findstr /IC:"Professional N" &&SET SLPKEY=XCVCF-2NXM9-723PB-MHCB7-2RYQQ
%RQR% | findstr /IC:"Professional with Media Center" &&SET SLPKEY=GNBB8-YVD74-QJHX6-27H4K-8QHDG
%RQR% | findstr /IC:"Enterprise" &&SET SLPKEY=NG4HW-VH26C-733KW-K6F98-J8CK4
%RQR% | findstr /IC:"Enterprise N" &&SET SLPKEY=JMNMF-RHW7P-DMY6X-RF3DR-X2BQT
%RQR% | findstr /IC:"Core" &&SET SLPKEY=BN3D2-R7TKB-3YPBD-8DRP2-27GG4
%RQR% | findstr /IC:"Core N" &&SET SLPKEY=8N2M2-HWPGY-7PGT9-HGDD8-GVGGY
%RQR% | findstr /IC:"CoreSingle Language" &&SET SLPKEY=2WN2H-YGCQR-KFX6K-CD6TF-84YXQ
%RQR% | findstr /IC:"CoreCountry Specific" &&SET SLPKEY=4K36P-JN4VD-GDC6V-KDT89-DYFKP
goto OEMINS

:Win8.1
ECHO 操作系统为 Windows 8.1 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Professional" &&SET SLPKEY=GCRJD-8NW9H-F2CDX-CCM8D-9D6T9
%RQR% | findstr /IC:"Professional N" &&SET SLPKEY=HMCNV-VVBFX-7HMBH-CTY9B-B4FXY
%RQR% | findstr /IC:"Professional with Media Center" &&SET SLPKEY=789NJ-TQK6T-6XTH8-J39CJ-J8D3P
%RQR% | findstr /IC:"Enterprise" &&SET SLPKEY=MHF9N-XY6XB-WVXMC-BTDCT-MKKG7
%RQR% | findstr /IC:"Enterprise N" &&SET SLPKEY=TT4HM-HN7YT-62K67-RGRQJ-JFFXW
%RQR% | findstr /IC:"Core" &&SET SLPKEY=M9Q9P-WNJJT-6PXPY-DWX8H-6XWKK
%RQR% | findstr /IC:"Core N" &&SET SLPKEY=7B9N3-D94CG-YTVHR-QBPX3-RJP64
%RQR% | findstr /IC:"CoreSingle Language" &&SET SLPKEY=BB6NG-PQ82V-VRDPW-8XVD2-V8P66
%RQR% | findstr /IC:"CoreCountry Specific" &&SET SLPKEY=NCTT7-2RGK8-WMHRF-RY7YQ-JTXG3
goto OEMINS

:Win10
ECHO 操作系统为 Windows 10 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Pro" &&SET SLPKEY=W269N-WFGWX-YVC9B-4J6C9-T83GX
%RQR% | findstr /IC:"Pro N" &&SET SLPKEY=MH37W-N47XK-V7XM9-C7227-GCQG9
%RQR% | findstr /IC:"ProStudent" &&SET SLPKEY=YNXW3-HV3VB-Y83VG-KPBXM-6VH3Q
%RQR% | findstr /IC:"ProStudent N" &&SET SLPKEY=8G9XJ-GN6PJ-GW787-MVV7G-GMR99
%RQR% | findstr /IC:"Pro 2015 LTSB N" &&SET SLPKEY=8Q36Y-N2F39-HRMHT-4XW33-TCQR4
%RQR% | findstr /IC:"Pro with Media Center" &&SET SLPKEY=NKPM6-TCVPT-3HRFX-Q4H9B-QJ34Y
%RQR% | findstr /IC:"Enterprise" &&SET SLPKEY=NPPR9-FWDCX-D2C8J-H872K-2YT43
%RQR% | findstr /IC:"Enterprise N" &&SET SLPKEY=DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4
%RQR% | findstr /IC:"Education" &&SET SLPKEY=NW6C2-QMPVW-D7KKK-3GKT6-VCFB2
%RQR% | findstr /IC:"Education N" &&SET SLPKEY=2WH4N-8QGBV-H22JP-CT43Q-MDWWJ
%RQR% | findstr /IC:"Enterprise 2015 LTSB" &&SET SLPKEY=WNMTR-4C88C-JK8YV-HQ7T2-76DF9
%RQR% | findstr /IC:"Enterprise 2015 LTSB N" &&SET SLPKEY=2F77B-TNFGY-69QQF-B8YKP-D69TJ
%RQR% | findstr /IC:"Enterprise 2016 LTSB" &&SET SLPKEY=DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ
%RQR% | findstr /IC:"Enterprise 2016 LTSB N" &&SET SLPKEY=QFFDN-GRT3P-VKWWX-X7T3R-8B639
%RQR% | findstr /IC:"Core" &&SET SLPKEY=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
%RQR% | findstr /IC:"Core N" &&SET SLPKEY=3KHY7-WNT83-DGQKR-F7HPR-844BM
%RQR% | findstr /IC:"CoreSingle Language" &&SET SLPKEY=7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH
%RQR% | findstr /IC:"CoreCountry Specific" &&SET SLPKEY=PVMJN-6DFY6-9CCP6-7BKTT-D3WVR
goto OEMINS

:2008
ECHO 操作系统为 Windows Server 2008 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Web Server 2008" &&SET SLPKEY=WYR28-R7TFJ-3X2YQ-YCY4H-M249D
%RQR% | findstr /IC:"Standard" &&SET SLPKEY=TM24T-X9RMF-VWXK6-X8JC9-BFGM2
%RQR% | findstr /IC:"Standard without Hyper-V" &&SET SLPKEY=W7VD6-7JFBR-RX26B-YKQ3Y-6FFFJ
%RQR% | findstr /IC:"Enterprise" &&SET SLPKEY=YQGMW-MPWTJ-34KDK-48M3W-X4Q6V
%RQR% | findstr /IC:"Enterprise without Hyper-V" &&SET SLPKEY=39BXF-X8Q23-P2WWT-38T2F-G3FPG
%RQR% | findstr /IC:"HPC" &&SET SLPKEY=RCTX3-KWVHP-BR6TB-RB6DM-6X7HP
%RQR% | findstr /IC:"Datacenter" &&SET SLPKEY=7M67G-PC374-GR742-YH8V4-TCBY3
%RQR% | findstr /IC:"Datacenter without Hyper-V" &&SET SLPKEY=22XQ2-VRXRG-P8D42-K34TD-G3QQC
%RQR% | findstr /IC:"for Itanium-Based Systems" &&SET SLPKEY=4DWFP-JF3DJ-B7DTH-78FJB-PDRHK
goto OEMINS

:2008R2
ECHO 操作系统为 Windows Server 2008 R2 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Web" &&SET SLPKEY=6TPJF-RBVHG-WBW2R-86QPH-6RTM4
%RQR% | findstr /IC:"Standard" &&SET SLPKEY=YC6KT-GKW9T-YTKYR-T4X34-R7VHC
%RQR% | findstr /IC:"Enterprise" &&SET SLPKEY=489J6-VHDMP-X63PK-3K798-CPX3Y
%RQR% | findstr /IC:"Datacenter" &&SET SLPKEY=74YFP-3QFB3-KQT8W-PMXWJ-7M648
%RQR% | findstr /IC:"HPCedition" &&SET SLPKEY=TT8MH-CG224-D3D7Q-498W2-9QCTX
%RQR% | findstr /IC:"forItanium-BasedSystems" &&SET SLPKEY=GT63C-RJFQ3-4GMB6-BRFB9-CB83V
goto OEMINS

:2012
ECHO 操作系统为 Windows Server 2012 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"N" &&SET SLPKEY=8N2M2-HWPGY-7PGT9-HGDD8-GVGGY
%RQR% | findstr /IC:"Single Language" &&SET SLPKEY=2WN2H-YGCQR-KFX6K-CD6TF-84YXQ
%RQR% | findstr /IC:"Country Specific" &&SET SLPKEY=4K36P-JN4VD-GDC6V-KDT89-DYFKP
%RQR% | findstr /IC:"Server Standard" &&SET SLPKEY=XC9B7-NBPP2-83J2H-RHMBY-92BT4
%RQR% | findstr /IC:"MultiPoint Standard" &&SET SLPKEY=HM7DN-YVMH3-46JC3-XYTG7-CYQJJ
%RQR% | findstr /IC:"MultiPoint Premium" &&SET SLPKEY=XNH6W-2V9GX-RGJ4K-Y8X6F-QGJ2G
%RQR% | findstr /IC:"Datacenter" &&SET SLPKEY=48HP8-DN98B-MYWDG-T2DCC-8W83P
goto OEMINS

:2012R2
ECHO 操作系统为 Windows Server 2012 R2 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Standard" &&SET SLPKEY=D2N9P-3P6X9-2R39C-7RTCD-MDVJX
%RQR% | findstr /IC:"Datacenter" &&SET SLPKEY=W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9
%RQR% | findstr /IC:"Essentials" &&SET SLPKEY=KNC87-3J2TX-XB4WP-VCPJV-M4FWM
goto OEMINS

:2016
ECHO 操作系统为 Windows Server 2016 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Datacenter" &&SET SLPKEY=CB7KF-BWN84-R7R2Y-793K2-8XDDG
%RQR% | findstr /IC:"Standard" &&SET SLPKEY=WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
%RQR% | findstr /IC:"Essentials" &&SET SLPKEY=JCKRF-N37P4-C2D82-9YXRT-4M63B
goto OEMINS

:2019
ECHO 操作系统为 Windows Server 2019 检测 操作系统版本匹配序列号...
%RQR% | findstr /IC:"Datacenter" &&SET SLPKEY=WMDGN-G9PQG-XVVXX-R3X43-63DFG
%RQR% | findstr /IC:"Standard" &&SET SLPKEY=N69G4-B89J2-4G8F4-WWYCC-J464C
%RQR% | findstr /IC:"Essentials" &&SET SLPKEY=WVDHN-86M7X-466P6-VHXV7-YY726
goto OEMINS

:OEMINS
ECHO 删除原有序列号中...
cscript //nologo %Systemroot%\system32\slmgr.vbs -upk
ECHO 安装序列号中...
cscript //nologo %Systemroot%\system32\slmgr.vbs -ipk %SLPKEY%
cscript //nologo %Systemroot%\system32\slmgr.vbs -skms kms.g6p.cn
ECHO 检测激活...
cscript //nologo %Systemroot%\system32\slmgr.vbs -ato
cscript //nologo %Systemroot%\system32\slmgr.vbs -dlv
PAUSE