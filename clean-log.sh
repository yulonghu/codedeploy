#!/bin/bash
# ---------------------------------------------------------------
# 清理用户登录日志 & 命令记录
#
# Filename: clean-log.sh
# Copyright: (c) 2016 360 Free WiFi Team. (http:://wifi.360.cn)
# License: http://www.apache.org/licenses/LICENSE-2.0
# ---------------------------------------------------------------

# 系统的每一次登录, 二进制文件
# view: last -f /var/log/wtmp
echo > /var/log/wtmp

# 件记录错误的登录尝试
# view: lastb -f /var/log/btmp
echo > /var/log/btmp

# 如果没有这个文件, 重启syslog进程service syslog restart
echo > /var/log/secure
echo > .bash_history

# 清除命令记录
history -c


echo 'clean log omplete!'
