#!/bin/bash
#
#小文件可以采用以下方法
# a=`awk '{print $11}'  access_ds.log|tr '\n' '+'`
# echo ${a%+}|bc
#
log_dir=/tmp
for i in `ls -1 ${log_dir}`
do
    LINE_WC=`echo "$i"|grep "^access.*log$"|wc -l`
    if [ ${LINE_WC} -eq 1 ]; then
        count_size=0
        while read line
        do
            size=`echo "${line}"|awk '{print $11}'`
            size=${size:-0}
            echo $size
            ((count_size+=size))
        done < ${log_dir}/$i
        count_kb=$((count_size/1024))
        count_kb=${count_kb:-1}

        if [ "${count_kb}" == "0" ]; then
            count_kb=1
        fi
        
        echo "file:${log_dir}/$i access_size:${count_kb}KB"
        count_size=0
    else
        continue
    fi
done
