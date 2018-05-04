#!/usr/bin/env bash

OPENRESTY_INSTALL_PATH="/usr/local/opt/openresty"

echo "检测nginx是否启动"
count=$(pgrep -f nginx |wc -l) #统计nginx进程数

if [ "${count}" -gt 1 ]
then
    echo "nginx 已经启动,开始重启nginx"
    $OPENRESTY_INSTALL_PATH/nginx/sbin/nginx -c /lua-kafka-gateway/conf/nginx.conf -s reload
else
    echo "nginx 没有启动,开始启动nginx"
    $OPENRESTY_INSTALL_PATH/nginx/sbin/nginx -c /lua-kafka-gateway/conf/nginx.conf
fi

count=$(pgrep -f nginx |wc -l)

if [ "${count}" -gt 2 ]
then
    echo "nginx 启动成功"
else
    echo "nginx 启动失败"
fi
