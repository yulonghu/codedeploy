# 代码部署系统

日常开发中，经常会有把本地的代码push到qa机器、worker机器、正式环境机器，无底线的手动重复操作为我们的工作增添了太多的枯燥。<br />
如果需要同步代码的机器有很多台，每次手动去操作实在是在给自己找麻烦。<br />
如果你没有一套好用的代码推送系统、或者正在苦寻，那么这套基于shell deploy也许是你不错的选择！<br />

支持多项目、多集群、多模式的代码部署系统。

conf.sh 脚本是deploy配置文件，其它文件不要去改动它。

非正式的线上环境机器，谁最后一次部署的代码，需要本人才能解锁，防止代码被冲洗。<br />
采用轮询推送，如果某集群有100台机器，在推送这集群的时候，其中有几台机器推送失败了，继续推送当前的版本即可。已经是最新代码的机器会被跳过。

注：
集群代码部署, 建议配置好无密码登录(RSA密钥认证)。否则部署过程中每一台机器都需要手动输入用户(conf.sh中变量SSH_USER)密码。

## 命令手册

git 模式用法: 

sh deploy-qa.sh     分支名称 qa集群编号<br />
sh deploy-ot.sh 分支名称 online集群编号<br />
sh deploy-worker.sh 分支名称 worker集群编号<br />

file 模式用法: 

sh deploy-qa.sh     file qa集群编号<br />
sh deploy-ot.sh file online集群编号<br />
sh deploy-worker.sh file worker集群编号<br />

两种模式通用, 释放当前用户占用机器例子:

sh deploy-qa.sh     clean qa集群编号<br />
sh deploy-ot.sh clean online集群编号<br />
sh deploy-worker.sh clean worker集群编号<br />

git 模式部署代码例子:

注意: 建议把部署系统全部代码解压到 git 项目根目录<br />
将分支dev推送到 [ qa1 ] 单台机器/集群: sh deploy-qa.sh dev 1<br />
将分支dev推送到 [ qa2 ] 单台机器/集群: sh deploy-qa.sh dev 2<br />

file 模式部署代码例子:

注: file模式第一个参数必须是固定的 file<br />
把/www/deploy.cn目录下的全部文件推送到 [ qa1 ] 单台机器/集群: sh deploy-qa.sh file 1<br />
把/www/deploy.cn目录下的全部文件推送到 [ qa2 ] 单台机器/集群: sh deploy-qa.sh file 2<br />

## 释放对机器的独占模式，让其他同事可以部署代码。

sh deploy-qa.sh     clean 集群编号<br />
sh deploy-worker.sh clean 集群编号<br />
sh deploy-ot.sh clean 集群编号<br />

## 多服务器批处理命令执行

Debug模式:   sh exec.sh "command" debug<br />
非Dubug模式: sh exec.sh "command"<br />

只需要配置一个, 多个主机之间用空格分割: vim conf.sh<br />
EXEC_HOSTS='test01v.add..net test02v.add.net'<br />

## 特别感谢

蔡玉光

## 联系我们

Site: http://www.cdvphp.com/wiki/index.php?title=Cd_start<br />
QQ群: 26778603


