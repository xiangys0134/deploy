#/bin/bash
if [ $# -ne "1"  ]
    then
    echo "input error" 
fi
Status=$1
case $Status in
         CLOSED)
            netstat -antp | grep CLOSED | wc -l
            ;;
         LISTEN)
            netstat -antp | grep LISTEN | wc -l
            ;;
       SYN_RECV)
            netstat -antp | grep SYN_RECV | wc -l
            ;;
       SYN_SENT)
            netstat -antp | grep SYN_SENT | wc -l
            ;;
    ESTABLISHED)
            netstat -antp | grep ESTABLISHED | wc -l
            ;;
      FIN_WAIT1)
            netstat -antp | grep FIN_WAIT1 | wc -l
            ;;
      FIN_WAIT2)
            netstat -antp | grep FIN_WAIT2 | wc -l
            ;;
     ITMED_WAIT)
            netstat -antp | grep ITMED_WAIT | wc -l
            ;;
        CLOSING)
            netstat -antp | grep CLOSING | wc -l
            ;;
      TIME_WAIT)
            netstat -antp | grep TIME_WAIT | wc -l
            ;;
       LAST_ACK)
            netstat -antp | grep LAST_ACK | wc -l
            ;;
           *)
             echo "Usage:$1(CLOSED|LISTEN|SYN_RECV|SYN_SENT|ESTABLISHED|FIN_WAIT1|FIN_WAIT2|ITMED_WAIT|CLOSING|TIME_WAIT|LAST_ACK)"
             ;;
esac


