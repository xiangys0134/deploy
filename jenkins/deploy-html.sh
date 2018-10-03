#! /bin/bash
#
#       $1 --> jenkins's workspace path
#       $2 --> job name
#       $3 --> remote login user's name
#       $4 --> remote ip address.
#       $5 --> remote server's program's startup script.
#       $6 --> environment select, default is test or distelopment.

DEPLOY_ENV=`echo ${4} | awk -F':' '{printf $1}'`
DEPLOY_TO=`echo ${4} | awk -F':' '{print $2}' | sed 's#,# #g'`

DATE=`date +%Y%m%d%H%M%S`
# copy program to remote server.
if [ $DEPLOY_ENV == "test" ] || [ $DEPLOY_ENV == "pro" ];then
        cd $1/dist/; tar -zcf ../$2-$DATE.tar.gz *;
        for ipaddr in ${DEPLOY_TO};
        do
                ssh $3@${ipaddr} -p $5 "cd /data/$3/ && if [ ! -d "code/$6/$2-$DATE" ];then mkdir -p "code/$6/$2-$DATE"; fi";
                scp -P $5 $1/$2-$DATE.tar.gz $3@${ipaddr}:/data/$3/;
                ssh $3@${ipaddr} -p $5 "cd /data/$3/ && \
                                        tar xf $2-$DATE.tar.gz -C code/$6/$2-$DATE/ && \
                                        rm -f $2-$DATE.tar.gz && \
                                        rm -f /data/wwwroot/$6 && \
                                        ln -s /data/$3/code/$6/$2-$DATE /data/wwwroot/$6";
        done;
else
        echo "Input Error!";
fi
