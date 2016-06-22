#!/bin/bash
# ---------------------------------------------------------------
# 公共函数库
#
# Filename: function.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

# 帮助说明
function showHelp()
{
    cecho -n -hl "[HELP]" -n
    cecho "git 模式用法:"
    cecho -g "sh deploy-qa.sh     分支名称 集群编号"
    cecho -g "sh deploy-ot.sh     分支名称 集群编号"
    cecho -g "sh deploy-worker.sh 分支名称 集群编号"
    cecho ""
    cecho "file 模式用法:"
    cecho -g "sh deploy-qa.sh     file 集群编号"
    cecho -g "sh deploy-ot.sh     file 集群编号"
    cecho -g "sh deploy-worker.sh file 集群编号"
    cecho ""
    cecho "两种模式通用, 释放当前用户占用机器例子:"
    cecho -g "sh deploy-qa.sh     clean 集群编号"
    cecho -g "sh deploy-ot.sh     clean 集群编号"
    cecho -g "sh deploy-worker.sh clean 集群编号"
    cecho ""
    cecho "git模式部署代码例子:"
    cecho "将分支dev推送到 [ $CURRENT_ACTION 1 ] 单台机器/集群:" -g " sh deploy-${CURRENT_ACTION}.sh dev 1"
    cecho "将分支dev推送到 [ $CURRENT_ACTION 2 ] 单台机器/集群:" -g " sh deploy-${CURRENT_ACTION}.sh dev 2"
    cecho ""
    cecho "file模式部署代码例子:"
    cecho "把/www/deploy.cn目录下的全部文件推送到 [ $CURRENT_ACTION 1 ] 单台机器/集群:" -g " sh deploy-${CURRENT_ACTION}.sh file 1"
    cecho "把/www/deploy.cn目录下的全部文件推送到 [ $CURRENT_ACTION 2 ] 单台机器/集群:" -g " sh deploy-${CURRENT_ACTION}.sh file 2"
    cecho -n -r "注意: 建议把部署系统全部代码解压到 git 项目根目录!" -n
    exit 0
}

# 帮助说明 exec.sh
function showHelpByExec()
{
    cecho -n -hl "[HELP]" -n
    cecho "说明: 通过公共授权账户, 多服务器执行批处理命令脚本"
    cecho "参数: 第一个参数要用双引号包起来; 第二个参数等于debug开启调试模式"
    cecho ""
    cecho "第一步: 先切换到公共授权账户(如):" -g " sudo su sync_user"
    cecho "第二步:" -g " sh exec.sh \"shell 命令语句\""
    cecho ""
    cecho "Example #1:"
    cecho -g "sh exec.sh \"执行命令语句\""
    cecho ""
    cecho "Example #2: (重定向输出到 xxx.log)"
    cecho -g "sh exec.sh \"执行命令语句\" > xxx.log"
    cecho ""
    cecho "Example #3: (开启debug调试模式)"
    cecho -g "sh exec.sh \"执行命令语句\" debug"
    cecho ""
    exit 0
}

# 初始化
function init()
{
    mkdir -p $LOCAL_CODEDEPLOY_TMP_DIR;
    chmod 733 $LOCAL_CODEDEPLOY_TMP_DIR 1>/dev/null 2>&1
    chmod 733 $LOCAL_CODEDEPLOY_TMP_DIR/.. 1>/dev/null 2>&1
}

# 获取当前系统时间
function getTime()
{
    date +%Y%m%d%H%M%S;
}

# 获取ms时间戳
function getMsTime()
{
    local current=`date "+%Y-%m-%d %H:%M:%S"` #获取当前系统时间      
    local timestamp=`date -d "$current" +%s` #将current转换为时间戳，精确到秒
    local current_timestamp=$((timestamp * 1000 + 10#`date "+%N"` / 1000000)) #将current转换为时间戳，精确到毫秒
    echo $current_timestamp
}

# $?
function checkExecResult()
{
    if [ $? != 0 ]; then
        INT_COUNT_FAILED=$((INT_COUNT_FAILED + 1))
        if [ ! -z "$1" ]; then
            ARR_FAILED_HOST="${ARR_FAILED_HOST} ${1}"
        fi
        continue
    fi
}

# check user
function checkLastUpdateUser()
{
    last_update_user=`$SSH $host "tail -n 1 ${REMOTE_CODEDEPLOY_ALLUSER_LOG} 2>/dev/null"`
    if [ ! -z "$last_update_user" ] && [ "$USER" != "$last_update_user" ]; then
        cecho $no". " -c "${host}" -w " => " -w "环境已经被用户" -r " $last_update_user  " -w "占用, 请自行联系协调操作!"
        continue
    fi
}

# show method
function showMsg()
{
    echo ""
    echo "[${1}]"
    echo ""
}

# 判断整数
function isInt()
{
    if [[ $1 != *[!0-9]* ]]; then
        echo 0
    else
        echo -1
    fi
}

# 检测网速
function checkSpeed()
{
    if [ $1 -lt 500 ]; then
        echo -w "$1 ms\t[" -g "非常快" -w "]"
    elif [ $1 -lt 1000 ]; then
        echo -w "$1 ms\t[" -y "中等" -w "]"
    else
        echo -w "$1 ms\t[" -r "太慢了" -w "]"
    fi
}

# 确认用户的输入
confirm()
{
    if [ $LANGUAGE = "utf-8" ]
    then
        message=$1
    else
        echo $1 > /tmp/exec_tools_tmp
        message=`iconv -f "utf-8" -t $LANGUAGE /tmp/exec_tools_tmp`
        rm -f /tmp/exec_tools_tmp
    fi
    while [ 1 = 1 ]
    do
        cread -p "$message [y/n]: " CONTINUE
        if [ "y" = "$CONTINUE" ]; then
            return 1;
        fi

        if [ "n" = "$CONTINUE" ]; then
            return 0;
        fi
    done

    return 0;
}

cread()
{
    read $1 "$2" $3
    tput sgr0 # Reset to normal.
    return
}

cdate()
{
    cdate=`date "+%Y-%m-%d %H:%M:%S"`
    cecho "  当前系统时间: $cdate \n"
    return
}

# 写入失败log文件
writeLogFile()
{
   echo $2 > $1
}

# 清理日志文件
clearLogFile()
{
    if [ -f $1 ]; then
        rm -f $1
    fi
}

# 检查上一次部署是否存在未清理的机器
checkLastPublish()
{
    if [ -f $1 ]; then
        local failed_rs=`cat $1`
    else
        return 0
    fi

    cecho -r "检测到上一次部署失败的主机 ... ..."
    echo ""

    for host in $failed_rs
    do
        i=$((i + 1))
        cecho -w "${i}. " $host -w " => " -r "失败 !"
    done

    echo ""

    while [ 1 = 1 ]
    do
        cread -p "是否需要处理? [y/n]: " CONTINUE
        if [ "y" = "$CONTINUE" ]; then
            echo ""
            hosts=$failed_rs
            return 1;
        fi

        if [ "n" = "$CONTINUE" ]; then
            echo ""
            return 0;
        fi
    done
}

# 计算文件大小
getFileSize()
{
    if [ -f $1 ]; then
        local size=`du -sh $1 | awk '{print $1}'`
        echo $size
    else
        echo 0
    fi
}

# 获取uname
function getOs()
{
	uname -s
}

# ----------------------------------------------------
# 获取文件列表
# getFileList root_dir blacklist node1 node2 node3
# node 可以是文件，也可以是文件夹
# ----------------------------------------------------
function getFileList()
{
    local files=''
    local root_dir="${1}/"
    local blists=''
    local dir_len=0;

    dir_len=`echo "${root_dir}" | wc -m`

    for blist in $BLACKLIST
    do
        blists="${blists}|.${blist}"
    done

    if [ $(getOs) == "Linux" ]
    then
        files=`echo "find ${root_dir}./ -regextype posix-extended -type f -not -regex '$blists' | cut -c '$dir_len-1000' | xargs echo" | bash`
    else
        # FreeBSD
        files=`echo "find -E ${root_dir}./ -type f -not -regex '$blists' | cut -c '$dir_len-1000' | xargs echo" | bash`
    fi

    echo $files
}

# find删除多少天之前的创建的文件
findDelCtime()
{
    find $1/*.gz -type f -ctime +${TAR_KEEP_TIME} -delete 1>/dev/null 2>&1
}

