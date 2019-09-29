# Rapid-APEX ([English](https://github.com/wfg2513148/rapid-apex) 中文)
[![APEX Tool](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/b7e95341/badges/apex-tool-badge.svg)](<LINK>) [![APEX Built with Love](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/7919f913/badges/apex-love-badge.svg)](<LINK>) [![APEX 5.0](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/88f0a6ed/badges/apex-5_0-badge.svg)](<LINK>) [![APEX 5.1](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/88f0a6ed/badges/apex-5_1-badge.svg)](<LINK>) [![APEX 18.1](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/2fee47b7/badges/apex-18_1-badge.svg)](<LINK>) [![APEX 18.2](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/2fee47b7/badges/apex-18_2-badge.svg)](<LINK>) [![APEX 18.2](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/apex-badges/APEX-19.1-blue.svg)](<LINK>) 


> [Oracle APEX](https://apex.oracle.com/zh-cn/) 的安装过程比较繁琐，涉及到东西比较多，特别是在结合ORDS时，总是容易犯错。另外，如果你想快速搭建一套测试环境，但需要特定版本的APEX/ORDS来验证测试某些功能时，每次重新搭环境也会浪费不少时间。
> [Rapid-APEX](https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX) 是可以让你从重复繁琐的安装过程中解脱出来，通过简单地设置你要搭建的环境信息，就可以生成对应的安装命令，直接执行即可完成相应的安装配置。

> 目前支持的产品版本:
> - **Oracle Database:** XE 18c
> - **Oracle APEX:** 19.1, 18.2, 18.1, 5.1.4, 5.0.4
> - **Oracle ORDS:** 19.2, 18.4, 18.2, 18.1, 3.0.12


# 创建新的APEX实例

## 生成安装命令

[https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX](https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX)

> 点击 "Generate New APEX Instance" 按钮

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926221241.png)

## 基本信息收集

> 在弹出窗口中，输入 **要安装的服务器IP地址**, **要安装的路径** and **操作系统版本**等信息。

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926222346.png)


## 数据库信息收集


![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190929131529.png)

> 当前只有 **Oracle Database XE 18c** 

> 对于安装文件，支持3种方式：
> 1. **快捷链接**: 选择快捷链接可以从默认的存储库下载安装介质 `AWS S3 (East Asia)`，速度可能比较慢；
> 2. **提供完整下载url**: 如果你已经将安装介质上传到互联网上，可以提供诸如下面格式的链接："`https://mybucket.s3.ap-northeast-1.amazonaws.com/oracle-database-xe-18c-1.0-1.x86_64.rpm`"
> 3. **提供服务器上的路径**: 如果你已经将安装介质下载到待安装的服务器，可以提供下列格式的地址："`/root/oracle-database-xe-18c-1.0-1.x86_64.rpm`"


## APEX 信息收集

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190929131648.png)

## ORDS 信息收集

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190929131726.png)


## 恭喜!!

> 你已经完成最难的部分了，接下来你要做的就是：
> - **复制**生成的安装命令,
> - **粘贴**进你的远程命令执行窗口,
> - **回车**启动安装;
> - 点击"**Finish**"按钮保存你的配置。 


![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927130215.png)


# 安装你的新APEX实例

## 执行安装命令


![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926223113.png)

> 整个安装过程可能持续几十分钟到几个小时（这取决于你的安装介质下载的速度）。 
> 如果一切顺利，你将看到以下提示。 

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190928074719.png)

# 验证你的新的APEX实例
## 检查Docker镜像/容器状态

> 执行以下命令，正常情况下，安装脚本会自动生成两个docker进程，并且状态应该是'healthy'；

```
docker ps -a
```

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927130445.png)

> 默认生成的docker镜像；

```
docker images
```

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927130654.png)


## 登录你的APEX实例

> 现在可以测试新生成的APEX实例了，输入你当时设置的连接信息，例如：

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926230438.png)

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927124836.png)

> 如果一切正常的话，应该可以登录你的APEX实例了。

## 连接你的数据库
### 在docker容器中连接数据库

连接字符串格式如下： 

- **CDB:** `sqlplus sys/oracle123@47.98.247.100:1521/XE as sysdba`
- **PDB:** `sqlplus sys/oracle123@47.98.247.100:1521/XEPDB1 as sysdba`


### 在docker容器外连接数据库

```
sqlplus sys/oracle@YOUR_REMOTE_SERVER_IP:YOUR_DB_PORT/XE as sysdba
sqlplus sys/oracle@YOUR_REMOTE_SERVER_IP:YOUR_DB_PORT/XEPDB1 as sysdba
```


## 修改配置信息（可选）

- **DB Data File:** `/root/rapid-apex/oradata/`
- **ORDS config file:** `/root/rapid-apex/oracle-ords/`


# 写在最后

> 现在，你有能力快速安装部署不同版本的APEX/ORDS环境了。如果你觉得还不错，记得在Github上给我打星哦! [https://github.com/wfg2513148/rapid-apex](https://github.com/wfg2513148/rapid-apex)
