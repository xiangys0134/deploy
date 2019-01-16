#!/usr/bin/env python

import arrow
import os
import json
from pygit2 import Repository

def check(path):
    repo = Repository(path)

    ret = {}
    ret['branch'] = repo.head.shorthand
    for i in repo.head.log():
        t = arrow.get(i.committer.time)
        ret['last_commited'] = t.to('Asia/Shanghai').format('YYYY-MM-DD HH:mm:ss ZZ')
        ret['oid'] = '{}'.format(i.oid_new)
        break
    return ret

with open("/data/script/sync-git-info/repos.txt", "r") as f:
    output = {}
    for i in f.readlines():
        i = i.replace('\n', '')
        if not os.path.isdir(i):
            continue
        output[i] = check(i)

    print(json.dumps(output))
