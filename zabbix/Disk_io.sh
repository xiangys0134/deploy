#/bin/bash
if [ $# -ne "1"  ]
    then
    echo "input error" 
fi
Device=sda
Disk=$1
case $Disk in
         rrqm)
            /usr/bin/iostat -dxkt |grep "\b$Device\b"|tail -1|awk '{print $2}'
            ;;
         wrqm)
            /usr/bin/iostat -dxkt |grep "\b$Device\b"|tail -1|awk '{print $3}'
            ;;
          rps)
            /usr/bin/iostat -dxkt |grep "\b$Device\b"|tail -1|awk '{print $4}'
            ;;
          wps)
            /usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $5}'
            ;;
        rKBps)
            /usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $6}'
            ;;
        wKBps)
            /usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $7}'
            ;;
        avgrq-sz)
            /usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $8}'
            ;;
        avgqu-sz)
            i/usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $9}'
            ;;
        await)
            /usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $(10)}'
            ;;
        svctm)
            i/usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $(13)}'
            ;;
         util)
            /usr/bin/iostat -dxkt |grep "\b$Device\b" |tail -1|awk '{print $(14)}'
            ;;
           *)
             echo "Usage:$1(rrqm|wrqm|rps|wps|rKBps|wKBps|avgrq-sz|avgqu-sz|await|svctm|util)"
             ;;
esac


