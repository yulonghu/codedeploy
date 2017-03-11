#!/bin/bash
# ---------------------------------------------------------------
# 代码部署系统版本号文件
#
# Filename: version.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

DEPLOY_DIRECTORY=`dirname $0`
. $DEPLOY_DIRECTORY/cecho.sh

CODE_DEPLOY_VERSION='1.1.6'
CODE_DEPLOY_UPTIME='2017/03/11'

cecho -w "This is Codedeploy System."
cecho -w "Version: " -g ${CODE_DEPLOY_VERSION}
cecho -w "LastUptime: " -g ${CODE_DEPLOY_UPTIME}
