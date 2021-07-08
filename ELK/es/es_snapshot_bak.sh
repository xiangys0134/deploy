#!/bin/bash
# es快照定时任务
# Author yousong.xiang
# Date 2021.7.6
# v1.0.1
# 首先需要配置es的快照仓库，参考文档：https://www.elastic.co/guide/cn/elasticsearch/guide/current/backing-up-your-cluster.html
# es-s3 plugins插件 官方文档：https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository-s3.html
# 创建仓库命令如下，需预先配置好s3的密钥(elasticsearch-keystore add s3.client.default.access_key,elasticsearch-keystore add s3.client.default.secret_key)
###################创建仓库命令###################
:<<EOF
PUT _snapshot/fastbull_repository
{
  "type": "s3",
  "settings": {
    "bucket": "repository-snapshot-es",
    "region": "eu-central-1"
  }
}
EOF
#################################################
repository='fastbull_repository'
log_path='/data/backup/snapshot-es-logs'
BAK_DATA=`date '+%Y.%m.%d'`
LAST_DATA=`date -d "-30 days" "+%Y.%m.%d"`
ip='172.23.11.100'
port='9200'

[ ! -d ${log_path} ] && mkdir -p ${log_path}

#所有索引打快照
result_json=`curl -XPUT "http://${ip}:${port}/_snapshot/${repository}/snapshot_all_${BAK_DATA}"`
ret=`echo $result_json|jq '.accepted'`

if [ "$ret" == "true" ]; then
  echo "${BAK_DATA} 备份快照成功!" >> ${log_path}/snapshot.log
else
  echo "${BAK_DATA} 备份快照失败!" >> ${log_path}/snapshot.log
fi

snapshot_json=`curl -XGET http://${ip}:${port}/_snapshot/${repository}/snapshot_all_${LAST_DATA}`
ret_code=`echo $snapshot_json|jq '.status'`
if [ "${ret_code}" -ne "404" ]; then
  echo "${BAK_DATA} 快照:snapshot_all_${LAST_DATA}删除成功" >> ${log_path}/snapshot.log
else
  echo "${BAK_DATA} 快照:snapshot_all_${LAST_DATA}不存在" >> ${log_path}/snapshot.log
fi
