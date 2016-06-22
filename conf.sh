#!/bin/bash
# ------------------------------------------------------
# 基础配置文件
#
# Filename: conf.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

# 如果会话是gbk, 请修改成gbk编码
export LANGUAGE="utf-8"

# 部署代码, 用到的用户, 整个系统通用
SSH_USER="public360"

# 所有用户: 本地上传代码时过滤这些文件或者文件夹, 支持通配符
BLACKLIST="*.log *.tmp *.svn.* *.swp /ENV /logs .gitignore .git"

# 本地、远程推送tar包保存时间(单位: 天), 支持小数、整数
# 推送代码中自动delete超过配置项时间的tar包
TAR_KEEP_TIME=10

# -------------------- 多服务端命令行搜索 start --------------------
# (可配置) 主机列表; 多个主机名称以空格分割(可以填写 IP地址、hostname)

EXEC_HOSTS='aaa.host.1  bbb.host.2 ccc.host.3'

# -------------------- 多服务端命令行搜索 end   --------------------

# -------------------- 项目1 git模式例子 带注释 --------------------
# 项目名称, 推送到远端机器会自动创建的文件夹名字
# 推送代码的方式
# git 基于git做代码的打包操作
# file 基于文本文件的打包操作
number=1
project_name[$number]="test.codedeploy.cn"

# 推送的机器, 可以填写IP地址、hostname 多台机器以空格分割
online[$number]=""

# 顾名思义, 这是测试机器了 
qa[$number]="test01v.ccc.hostname.net"

# 顾名思义, 这是worker机器了
worker[$number]=""

# 项目本地跟目录, 权限(wr)
local_web_path[$number]="/home/fanjiapeng/api"

# 项目部署到远端机器的目录, 前提这个目录有读写(wr)权限
remote_web_path[$number]="/home/web/test/${project_name[1]}"

# -------------------- 项目5 git模式例子 --------------------
number=2
project_name[$number]="test1.360.cn"
online[$number]="ot.hostname"
qa[$number]="qa.test1.360.cn"
worker[$number]=""
local_web_path[$number]="/home/fanjiapeng/project/conf"
remote_web_path[$number]="/home/web/${project_name[$number]}"

