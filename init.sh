#!/bin/bash
# ---------------------------------------------------------------
# 初始化代码部署系统
#
# Filename: init.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

SSH="sudo -u ${SSH_USER} ssh -o GSSAPIAuthentication=no"
SCP="sudo -u ${SSH_USER} scp -C"
RSYNC="rsync"

# 所有用户: 保存本地临时文件的公共目录, 所有用户部署的代码都会保存在这里
LOCAL_CODEDEPLOY_TMP_DIR="/tmp/codedeploy_tmp/${USER}"

# 当前用户: 线上每次收到代码, bak目录地址
REMOTE_CODEDEPLOY_HISTORY_DIR="/home/${SSH_USER}/codedeploy_history/${project_name[$params_2]}"

# 所有用户: 线上记录最后一次更新的用户名称
REMOTE_CODEDEPLOY_ALLUSER_LOG="${REMOTE_CODEDEPLOY_HISTORY_DIR}/codedeploy_alluser_log"

# 部署成功的机器数量
INT_COUNT_SUCCESS=0

# 部署失败的机器数量
INT_COUNT_FAILED=0

# 部署失败的机器列表
ARR_FAILED_HOST=""

