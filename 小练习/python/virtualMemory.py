#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# yousong.xiang
# 2022.3.4
# v1.0.1
# 功能: 查看Linux分区可用空间

import psutil,logging,os

result = psutil.virtual_memory()
vm_percent = result.percent
vm_available = result.available / 1024 / 1024

rs_log = os.path.join('/tmp','vm.log')
logging.basicConfig(
    level=logging.INFO,
    filename=rs_log,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

logger = logging.getLogger('vm')

if vm_percent >= 95:
    logger.info('内存使用率大于95%%,可用内存%sM'%vm_available)

