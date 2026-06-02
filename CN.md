# Rapid-APEX ([English](https://github.com/wfg2513148/rapid-apex) [中文](https://github.com/wfg2513148/rapid-apex/blob/master/CN.md))



> [Oracle APEX](https://apex.oracle.com/zh-cn/) 的安装过程比较繁琐，涉及到东西比较多，特别是在结合ORDS时，总是容易犯错。另外，如果你想快速搭建一套测试环境，但需要特定版本的APEX/ORDS来验证测试某些功能时，每次重新搭环境也会浪费不少时间。
> [Rapid-APEX](https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX) 是可以让你从重复繁琐的安装过程中解脱出来，通过简单地设置你要搭建的环境信息，就可以生成对应的安装命令，直接执行即可完成相应的安装配置。

> 当前版本目录支持的产品版本:
> - **Oracle Database:** XE 18c, 19c Enterprise, 26ai Free, 26ai Enterprise
> - **Oracle APEX:** 26.1, 24.2, 24.1, 23.2, 23.1, 22.2, 22.1, 21.2, 21.1, 20.2, 20.1, 19.2, 19.1, 18.2, 18.1, 5.1.4, 5.0.4
> - **Oracle ORDS:** 26.x, 25.x, 24.x, 23.x, 22.x, 21.x, 20.x, 19.2, 18.4, 18.2, 18.1, 3.0.12
>
> 原始安装脚本仍是 Oracle Database XE 18c 的 legacy 链路。19c、26ai 以及新版 ORDS 的完整安装链路会按版本目录继续现代化实现。

# CLI 预览

新的 CLI 会作为一站式 APEX demo/test 环境的统一入口。目前已支持版本查看、profile 校验、安装前检查、状态/日志/清理辅助命令和 dry-run 安装计划。

```bash
bin/rapid-apex list-versions
bin/rapid-apex validate --db 26ai --apex 26.1 --ords 26
bin/rapid-apex plan --db 26ai --apex 26.1 --ords 26 --name apex261-lab
bin/rapid-apex preflight --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex install --dry-run --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex status --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex logs --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex smoke --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex browser-smoke --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex e2e --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex destroy --profile profiles/26ai-apex261-ords26.env
```

默认数据库安装策略是 `demo`，只允许 Oracle XE 或 Free 版本。Enterprise Edition 场景统一视为 BYOL 目标，需要显式确认用户已具备有效 Oracle license/terms：

```bash
bin/rapid-apex plan --db 19c --apex 24.2 --ords 25 --license-policy byol
bin/rapid-apex plan --db 26ai-ee --apex 26.1 --ords 26 --license-policy byol
```

`e2e` 是脚本化端到端链路：会依次执行 preflight、安装、容器状态检查、HTTP smoke 检查，以及真实浏览器验证。浏览器验证会登录 `demo` workspace，创建一个新的 APEX application，并用 `demo/demo` 登录新应用。默认截图证据会写入 `.rapid-apex/evidence/<lab-name>/`。只有需要验证后停止环境时才加 `--destroy-after`；如果连生成的数据目录也要删除，再加 `--purge-data`。

Rapid-APEX 会优先使用 Oracle Container Registry 上的 Oracle 官方 Database / ORDS 镜像。旧 Dockerfile 构建链路只作为没有官方镜像路径时的 fallback。
新版 ORDS 官方镜像计划默认使用固定的大版本 tag，不再漂移到 `latest`；如果需要指定 Oracle 已发布的具体补丁 tag，可以使用 `--ords-image-tag TAG` 覆盖。
企业版数据库镜像也可以通过 `--db-image IMAGE` 覆盖，适配 Oracle 针对特定大版本发布的授权镜像 tag。

当前真实执行链路支持 legacy 18c XE + ORDS 3/18/19/20/21 组合，以及现代 Database + ORDS 官方镜像 profiles。legacy 和官方镜像安装都会自动创建 `demo` workspace 和 `demo/demo` 开发者账号，用于真实浏览器验收。

已完成真实安装验证的 profile 范围包括：

| Database | APEX | ORDS | Profile |
| --- | --- | --- | --- |
| 18c XE | 5.1.4, 18.2, 19.1, 20.2, 21.2 | 3.0.12, 18.4, 19.2, 20.x, 21.x | `profiles/18c-*` |
| 26ai Free | 22.2, 23.2, 24.1, 26.1 | 22.x, 23.x, 24.x, 26.x | `profiles/26ai-*` |
| 19c Enterprise BYOL | 22.1, 23.1, 24.2 | 23.x, 24.x, 25.x | `profiles/19c-*` |
| 26ai Enterprise BYOL | 26.1 | 26.x | `profiles/26ai-ee-*` |


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
