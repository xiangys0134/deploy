#!/usr/bin/env python3
# -*- coding:utf-8 -*-

from random import choice

def createRandom(args):
    lst1 = list(range(48,58))
    lst2 = list(range(65,91))
    lst3 = list(range(97, 123))

    lst1.extend(lst2)
    lst1.extend(lst3)

    if not str(args).isdigit() or str(args)== '0':
        return False

    if not isinstance(args,int):
        return False

    num_list = []
    for i in range(args):
        num_list.append(str(chr(choice(lst1))))
    return ''.join(num_list)


res = createRandom(6)
print(res)
