#!/usr/bin/env bash

OPENRESTY_INSTALL_PATH="/usr/local/opt/openresty"

echo "检测nginx是否启动"
count=$(pgrep -f nginx |wc -l) #统计nginx进程数

if [ "${count}" -gt 1 ]
then
    echo "nginx 已经启动,开始停止nginx"
    $OPENRESTY_INSTALL_PATH/nginx/sbin/nginx  -c  /lua-kafka-gateway/conf/nginx.conf -s quit
    echo "nginx 已经停止"
else
    echo "nginx 没有启动,开始启动nginx"
fi

