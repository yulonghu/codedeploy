#!/bin/bash
# ---------------------------------------------------------------
# 多服务器命令批量执行脚本
#
# Filename: exec.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

FILENAME=$0

# load function
DEPLOY_DIRECTORY=`dirname $FILENAME`
. $DEPLOY_DIRECTORY/function.sh
. $DEPLOY_DIRECTORY/cecho.sh
. $DEPLOY_DIRECTORY/conf.sh
. $DEPLOY_DIRECTORY/init.sh

# 使用帮助
if [ $# -lt 1 ] || [ "-h" = "$1" ] || [ "--help" = "$1" ]; then
    showHelpByExec
fi

if [ $# == 2 ] &&[ "$2" == "debug" ]; then
    # 确认服务器列表
    cecho -n "============== 服务器列表(开始) ==============" -n
    no=0;
    for host in $EXEC_HOSTS
    do
        no=`echo "$no + 1" | bc`
        cecho $no".  "  -c "$host" 
        INT_COUNT_SUCCESS=$((INT_COUNT_SUCCESS + 1))
    done
    cecho -n  "============== 服务器列表(结束) ==============" -n
fi

confirm "确认服务器列表？"

# $? 上一个命令的退出码
if [ 1 != $? ]; then
    if [ $# == 2 ] &&[ "$2" == "debug" ]; then
        cecho -n "[" -p "result" -w "] 机器数量: " -g $INT_COUNT_SUCCESS -p " 放弃了本次操作!" -n
    fi
    exit 0;
fi

INT_COUNT_SUCCESS=0;
# 开始批处理执行命令
for host in $EXEC_HOSTS
do
    if [ $# == 2 ] &&[ "$2" == "debug" ]; then
        INT_COUNT_SUCCESS=$((INT_COUNT_SUCCESS + 1))
        cecho -n -w $INT_COUNT_SUCCESS". [ " -c "$host" -w " ]" -n
        $SSH $host "$1"
    else
        $SSH $host "$1"
    fi
done

if [ $# == 2 ] &&[ "$2" == "debug" ]; then
    cecho -n -g "[" -g "result" -w "] 机器数量: " -g $INT_COUNT_SUCCESS -w " Done!" -n
fi

