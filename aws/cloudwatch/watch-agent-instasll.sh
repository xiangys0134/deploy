#!/bin/bash
# Watch agent install.The base env amz linux 2
# Author: yousong.xiang
# Date:  2021.3.10
# Version: v1.0.1

agent_json=/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

yum install wget -y
cd /tmp
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm && rpm -ivh amazon-cloudwatch-agent.rpm
if [ $? -ne 0 ]; then
  echo "wget or install failed"
  exit 5
fi
cat >>${agent_json}<< EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "append_dimensions": {
            "InstanceId": "\${aws:InstanceId}"
        },
        "metrics_collected": {
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF
systemctl enable amazon-cloudwatch-agent.service
systemctl restart amazon-cloudwatch-agent.service
