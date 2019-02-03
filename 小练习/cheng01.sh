#!/bin/bash
#
#
BaseDir=`dirname $0`

echo -n "请输入数值:"
read number

expr ${number} + 0 &>/dev/null
REVELT=$?

if [ ${REVELT} -ne 0 ]; then
    echo "Please enter a number."
    exit 7
fi

Multiply() {
    num=$1
    for x in `seq -s " " ${num}`
    do
        for y in `seq -s " " ${x}`
        do
            #echo -n $x,$y
            echo -n "${x} * ${y} = `expr ${y} \* ${x}`  "
        done
        echo " "
    done


}

Multiply ${number}
