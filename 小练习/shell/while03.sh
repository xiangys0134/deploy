#!/bin/sh
#
i=1
sum=0

while ((i<=100))
do
    ((sum=sum+i))
    ((i++))
done
echo "sum=$sum"
