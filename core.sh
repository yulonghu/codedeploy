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
current_method=""

# 获取参数
params_1=$1
params_2=$2

# help
if [ "$params_1" == "-h" ] || [ "$params_1" == "-help" ] || [ "$params_1" == "--h" ] || [ "$params_1" == "--help" ]; then
    showHelp
fi

# 输出当前的模式
if [ $# == 2 ] && [ "$params_1" == "file" ]; then
    current_method="file"
    cecho -n -hl "[file模式 + ${CURRENT_ACTION}${params_2} 环境]" -n
elif [ $# == 2 ] && [ `isInt $params_2` == 0 ] && [ "$params_1" == "clean" ]; then
    cecho -n -hl "[${CURRENT_ACTION}${params_2} 环境] - [执行操作 ${params_1}]" -n
    current_method="git"
elif [ $# == 2 ] && [ `isInt $params_2` == 0 ]; then
    cecho -n -hl "[git模式] - [${CURRENT_ACTION}${params_2} 环境] - [推送分支 ${params_1}]" -n
    current_method="git"
else
    showHelp
fi

# load function
. $DEPLOY_DIRECTORY/conf.sh
. $DEPLOY_DIRECTORY/init.sh

# 初始化
LOCAL_CODEDEPLOY_TMP_DIR="${LOCAL_CODEDEPLOY_TMP_DIR}/${project_name[$params_2]}"
init

if [ "$CURRENT_ACTION" == "qa" ]; then
    hosts=${qa[$params_2]}
elif [ "$CURRENT_ACTION" == "worker" ]; then
    hosts=${worker[$params_2]}
else
    hosts=${online[$params_2]}
fi

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
last_failed_publish="${LOCAL_CODEDEPLOY_TMP_DIR}/failed.${CURRENT_ACTION}"

# --------------------- 清理本地超限时间包 (start) ---------------------
findDelCtime $LOCAL_CODEDEPLOY_TMP_DIR
# --------------------- 清理本地超限时间包 (end) -----------------------

# -------------------------- 释放环境 (start) --------------------------
if [ "$params_1" == "clean" ]; then
    for host in $hosts
    do
        no=$(($no + 1))
        checkLastUpdateUser

        $SSH $host "echo "" > ${REMOTE_CODEDEPLOY_ALLUSER_LOG} 2>/dev/null"

        if [ $? != 0 ]; then
            cecho $no". " -c "${host}" -w " => " -r "环境释放失败!"
        else
            clearLogFile $last_failed_publish
            cecho $no". " -c "${host}" -w " => " -g "环境释放成功."
        fi

    done

    echo ""
    exit 0
fi
# -------------------------- 释放环境 (end) ---------------------------

# -------------------------- 检查上次部署失败情况 (start) -------------
checkLastPublish $last_failed_publish
# -------------------------- 检查上次部署失败情况 (end) ---------------

# -------------------------- 打包代码 (start) --------------------------
CURRENT_TIME=`getTime`
file_name="codedeploy_${project_name[$params_2]}_${params_1}_${CURRENT_TIME}.tar.gz"
local_directory_package="${LOCAL_CODEDEPLOY_TMP_DIR}/${file_name}"

cecho -w "本地配置 [$params_2] 开始打包 ... ..."

# 非commit时, git archive错误提示: "fatal: current working directory is untracked"
# commit时, git archive 正确
# 兼容两种情况
# --verbose
if [ $current_method == "git" ]; then
    cd ${local_web_path[$params_2]} && git archive --format=tar.gz $params_1 -o $local_directory_package
else
    cd ${local_web_path[$params_2]} && tar -zcf $local_directory_package . ${exclude}
fi

if [ ! -s "$local_directory_package" ]; then
    echo "本地配置 [$params_2] 打包失败!"
    exit -1
fi

filesize=`getFileSize $local_directory_package`
cecho -w "本地配置 [$params_2] 打包" -g "成功" -w ": ${local_directory_package}"
cecho -w "本地配置 [$params_2] 文件大小: " $filesize  -n

# -------------------------- 开始上传代码 (start) -------------------------- 
remote_directory_package="${REMOTE_CODEDEPLOY_HISTORY_DIR}/${file_name}"

no=0;
for host in $hosts
do
    no=$(($no + 1))
    checkLastUpdateUser

    if [ -z "$last_update_user" ]; then
        $SSH $host "mkdir -p ${REMOTE_CODEDEPLOY_HISTORY_DIR} && mkdir -p ${remote_web_path[$params_2]} 1>/dev/null"
        checkExecResult $host
    fi

    cecho $no". " -c "$host" -w " => 代码上传中 ... ..."

    start_time=`getMsTime`
    $SCP $local_directory_package ${host}:${remote_directory_package} 1>/dev/null
    end_time=`getMsTime`
    end_time=$((end_time - start_time))

    checkExecResult $host

    cecho $no". " -c "$host" -w " => 代码上传" -g "成功" -w ": $remote_directory_package"
    cecho $no". " -c "$host" -w " => 耗时: " $(checkSpeed $end_time)

    cecho $no". " -c "$host" -w " => 开始解压远程代码包 ... ..."
    $SSH $host "tar -zxmf $remote_directory_package ${exclude} -C ${remote_web_path[$params_2]}"
    cecho $no". " -c "$host" -w " => 代码解压" -g "成功" -w ": ${remote_web_path[$params_2]}"

    checkExecResult $host

    if [ -z "$last_update_user" ]; then
        $SSH $host "echo $USER > $REMOTE_CODEDEPLOY_ALLUSER_LOG"
    fi

    $SSH $host "sh ${remote_web_path[$params_2]}/project/autoload_builder.sh 1>/dev/null 2>&1"
    if [ $? == 0 ]; then
        cecho $no". " -c "$host" -w " => 执行远程autoload_builder脚本" -g "成功"
    fi

    cecho $no". " -c "$host" -w " => 清理远程过期的tar包"
    $SSH $host "find $REMOTE_CODEDEPLOY_HISTORY_DIR/*.gz -type f -ctime +${TAR_KEEP_TIME} -delete"

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

