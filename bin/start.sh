#!/usr/bin/env bash

echo "检测nginx是否启动"
count=$(ps -ef|grep "nginx" -c)

if [ $count -gt 1 ]
then
    echo "nginx 已经启动,开始重启nginx"
    openresty  -p "$PWD/" -c  "$PWD/conf/nginx.conf" -s reload
else
    echo "nginx 没有启动,开始启动nginx"
    openresty  -p "$PWD/" -c  "$PWD/conf/nginx.conf"
fi

count=$(ps -ef|grep "nginx" -c)

if [ $count -gt 2 ]
then
    echo "nginx 启动成功"
else
    echo "nginx 启动失败"
fi
