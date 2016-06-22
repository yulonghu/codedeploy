#!/bin/bash
# ---------------------------------------------------------------
# worker机器代码部署文件
#
# Filename: deploy-worker.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

# 配置当前动作, 调用conf.sh里不同的配置项
CURRENT_ACTION="worker"

FILENAME=$0

DEPLOY_DIRECTORY=`dirname $FILENAME`

# 开始执行代码部署
. $DEPLOY_DIRECTORY/core.sh
