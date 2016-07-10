#!/bin/bash
# ---------------------------------------------------------------
# 核心文件
#
# Filename: core.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

# 配置项
FILENAME=$0

# load function
DEPLOY_DIRECTORY=`dirname $FILENAME`
. $DEPLOY_DIRECTORY/cecho.sh
. $DEPLOY_DIRECTORY/function.sh

# 当前部署代码的模式
current_method="rsync"

# 获取参数
params_1=$1

# help
if [ -z "$params_1"] || [ "$params_1" == "-h" ] || [ "$params_1" == "-help" ] || [ "$params_1" == "--h" ] || [ "$params_1" == "--help" ]; then
    showHelpRsync
fi

# 输出当前的模式
if [ `isInt $params_1` == 0 ]; then
    cecho -n -hl "[rsync模式] - [环境 ${params_1}]" -n
else
    showHelpRsync
fi

# load function
. $DEPLOY_DIRECTORY/conf.sh
. $DEPLOY_DIRECTORY/init.sh

# 初始化
init

hosts=${rsync[$params_1]}

# 检查机器列表
if [ -z "$hosts" ]; then
    cecho -r "没有正确配置可用机器列表" -n
    exit -1
fi

# 黑名单
exclude=""
for back_list in $BLACKLIST
do
    exclude=" ${exclude} --exclude=${back_list}"
done
unset back_list

# 计数器
INT_COUNT_FAILED=0
INT_COUNT_SUCCESS=0
no=0
ARR_FAILED_HOST=''
filesize=0;

# 上一次部署失败log
last_failed_publish="${LOCAL_CODEDEPLOY_TMP_DIR}/${project_name[$params_1]}/failed.${CURRENT_ACTION}"

# -------------------------- 检查上次部署失败情况 (start) -------------
checkLastPublish $last_failed_publish
# -------------------------- 检查上次部署失败情况 (end) ---------------

# -------------------------- 开始上传代码 (start) -------------------------- 
no=0;
for host in $hosts
do
    no=`echo "$no + 1" | bc`

    cecho $no". " -c "$host" -w " => 代码同步中 ... ..."

    start_time=`getMsTime`
    msg=`$RSYNC -tIpgocrvl --delay-updates --timeout=60 $exclude ${local_web_path[$params_1]}/ ${SSH_USER}@${host}:${remote_web_path[$params_1]}/ 2>&1`
    end_time=`getMsTime`
    end_time=$((end_time - start_time))

    result=`echo $msg | grep -i 'error' | wc -L`

    if [  -z $result ]; then
        cecho $no". " -c "$host" -w " => 代码同步" -g "成功" -w ": ${remote_web_path[$params_1]}/"
        cecho $no". " -c "$host" -w " => 耗时: " $(checkSpeed $end_time)
    else
        cecho $no". " -c "$host" -w " => 代码同步" -r "失败" -w ": ${remote_web_path[$params_1]}/" -n
        cecho "失败原因:"
        cecho -r "${msg}"

        INT_COUNT_FAILED=$((INT_COUNT_FAILED + 1))
        if [ ! -z "${host}" ]; then
            ARR_FAILED_HOST="${ARR_FAILED_HOST} ${host}"
        fi
        continue
    fi

    INT_COUNT_SUCCESS=$((INT_COUNT_SUCCESS + 1))

    echo ""
done

# 显示部署代码的结果
if [ $INT_COUNT_FAILED -eq 0 ] && [ $INT_COUNT_SUCCESS -gt 0 ]; then
    cecho -n -w "[" -g "result" -w "] 机器数量: " -g $INT_COUNT_SUCCESS -w " 全部部署" -g "成功!"
    clearLogFile $last_failed_publish
elif [ $INT_COUNT_SUCCESS -gt 0 ]; then
    cecho -n -w "[" -g "result" -w "] 机器数量: " -g $INT_COUNT_SUCCESS -w " 部分机器部署" -g "成功!"
fi

if [ $INT_COUNT_FAILED -gt 0 ]; then
    cecho -n -w "[" -r "result" -w "] 机器数量: " -r $INT_COUNT_FAILED  -w " 部署失败机器如下:" -n
    i=0
    for host in $ARR_FAILED_HOST
    do
        i=$((i + 1))
        cecho -w "${i}. " $host -w " => " -r "失败 !"
    done

    #写入失败文件
    writeLogFile $last_failed_publish "${ARR_FAILED_HOST}"
fi

echo ""

