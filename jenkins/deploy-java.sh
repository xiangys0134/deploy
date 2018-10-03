#! /bin/bash
#
#	$1 --> jenkins's workspace path
#	$2 --> job name
#	$3 --> remote login user's name
#	$4 --> remote ip address.
#	$5 --> remote server's program's startup script.
#	$6 --> environment select, default is test or development.

DEPLOY_ENV=`echo ${4} | awk -F':' '{printf $1}'`
DEPLOY_TO=`echo ${4} | awk -F':' '{print $2}' | sed 's#,# #g'`
DATE=`date +%Y%m%d%H%M%S`;

if [[ $DEPLOY_ENV == "pro" ]] || [[ $DEPLOY_ENV == "test" ]] ;then
	# copy program to remote server.
	if [[ $DEPLOY_ENV == "pro" ]] ; then
		cd $1/target/; tar -cf $2-assembly.tar.gz --exclude=$2/WEB-INF/classes/config --exclude=$2/WEB-INF/classes/pnrKey --exclude=$2/WEB-INF/swagger --exclude=$2/WEB-INF/jsp $2;
	elif [[ $DEPLOY_ENV == "test" ]]; then
		cd $1/target/; tar -cf $2-assembly.tar.gz --exclude=$2/WEB-INF/classes/config --exclude=$2/WEB-INF/classes/pnrKey --exclude=$2/WEB-INF/jsp $2;
	fi	
	for ipaddr in ${DEPLOY_TO};
	do
		scp -P $6 $1/target/*.gz $3@${ipaddr}:/data/$3/;
		ssh $3@${ipaddr} -p $6 "cd /data/$3/ && sh /usr/bin/k_pid.sh $2 && if [ ! -d "code/$2" ];then mkdir -p "code/$2"; fi && cd code/$2/ && tar xf ../../$2*.gz -C . && mv $2 $2-$DATE && cd /data/$3/ && rm -f $2 && ln -s code/$2/$2-$DATE $2 ; rm -f $2-*.gz " ;
		scp -P $6 -q -r /data/config/$DEPLOY_ENV/$2/* $3@${ipaddr}:/data/$3/$2/WEB-INF/classes/;
		ssh $3@${ipaddr} -p $6 "cd /data/$3/ && cd tomcat-$2*/bin/ && sh $5" ;
		sleep 2;
	done
else
	echo "Input Error !";
fi
