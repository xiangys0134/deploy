#/bin/bash
if [ $# -ne "1"  ]
    then
    echo "input error" 
fi
Status=$1
case $Status in
         CLOSED)
            netstat -ant | grep CLOSED | wc -l
            ;;
         LISTEN)
            netstat -ant | grep LISTEN | wc -l
            ;;
       SYN_RECV)
            netstat -ant | grep SYN_RECV | wc -l
            ;;
       SYN_SENT)
            netstat -ant | grep SYN_SENT | wc -l
            ;;
    ESTABLISHED)
            netstat -ant | grep ESTABLISHED | wc -l
            ;;
      FIN_WAIT1)
            netstat -ant | grep FIN_WAIT1 | wc -l
            ;;
      FIN_WAIT2)
            netstat -ant | grep FIN_WAIT2 | wc -l
            ;;
     ITMED_WAIT)
            netstat -ant | grep ITMED_WAIT | wc -l
            ;;
        CLOSING)
            netstat -ant | grep CLOSING | wc -l
            ;;
      TIME_WAIT)
            netstat -ant | grep TIME_WAIT | wc -l
            ;;
       LAST_ACK)
            netstat -ant | grep LAST_ACK | wc -l
            ;;
           *)
             echo "Usage:$1(CLOSED|LISTEN|SYN_RECV|SYN_SENT|ESTABLISHED|FIN_WAIT1|FIN_WAIT2|ITMED_WAIT|CLOSING|TIME_WAIT|LAST_ACK)"
             ;;
esac
