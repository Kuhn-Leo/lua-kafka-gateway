#!/usr/bin/env bash

echo "检测nginx是否启动"
count=$(ps -ef|grep "nginx" -c)

if [ $count -gt 1 ]
then
    echo "nginx 已经启动,开始停止nginx"
    openresty -p "$PWD/"  -c "$PWD/conf/nginx.conf" -s quit
    echo "nginx 已经停止"
else
    echo "nginx 没有启动,开始启动nginx"
fi

