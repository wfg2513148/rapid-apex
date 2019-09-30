# Rapid-APEX ([English](https://github.com/wfg2513148/rapid-apex) [中文](https://github.com/wfg2513148/rapid-apex/CN.md))
[![APEX Tool](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/b7e95341/badges/apex-tool-badge.svg)](<LINK>) [![APEX Built with Love](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/7919f913/badges/apex-love-badge.svg)](<LINK>) [![APEX 5.0](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/88f0a6ed/badges/apex-5_0-badge.svg)](<LINK>) [![APEX 5.1](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/88f0a6ed/badges/apex-5_1-badge.svg)](<LINK>) [![APEX 18.1](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/2fee47b7/badges/apex-18_1-badge.svg)](<LINK>) [![APEX 18.2](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/2fee47b7/badges/apex-18_2-badge.svg)](<LINK>) [![APEX 18.2](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/apex-badges/APEX-19.1-blue.svg)](<LINK>) 



> [Rapid-APEX](https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX) is a tool taht allow you to quickly deploy a test environment of Oracle database, APEX and ORDS in docker. It will be very useful specially when you need a testing APEX environment but different product versions. 

> Supported Product List:
> - **Oracle Database:** XE 18c
> - **Oracle APEX:** 19.1, 18.2, 18.1, 5.1.4, 5.0.4
> - **Oracle ORDS:** 19.2, 18.4, 18.2, 18.1, 3.0.12


# Create Your New APEX Instance

## Get Installation Commands

[https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX](https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX)

> Click "Generate New APEX Instance" button

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926221241.png)

## Base Information Collection

> In the popup dialog, input your **remote machine IP address**, **installation path** and **OS version**

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926222346.png)


## Database Information Collection

> Complete database information collection. 

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190929131529.png)

> Currently **Oracle Database XE 18c** is supported only. 

> Three download options are acceptable:
> 1. **quick selection**: this will download installation file from default online storage `AWS S3 (East Asia)`;
> 2. **Provide valid full download url address**: provide such format if you have, "`https://mybucket.s3.ap-northeast-1.amazonaws.com/oracle-database-xe-18c-1.0-1.x86_64.rpm`"
> 3. **Provide valid full path which you have already downloaded**: such as "`/root/oracle-database-xe-18c-1.0-1.x86_64.rpm`"


## APEX Information Collection

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190929131648.png)

## ORDS Information Collection

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190929131726.png)


## Congratulations!!

> Now you have finished the most difficult part, what you need to do in next step is: 
> - **copy** generated commands,
> - **paste** it into a terminal window,
> - enter "**return**" key to trigger installation process;
> Of course you can click "**Finish**" button on the right top of page to save your configuration. 


![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927130215.png)


# Install Your New APEX Instance

## Execute Installation Commands

> Copy above generated commands and paste to terminal window of your remote server. 

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926223113.png)

> The installation process may take <u>30 minites or several hours</u> since it will download installation media from my AWS S3 bucket (East Asia), build docker images of database & ORDS and startup them automatically. 
> You can get a cup of coffie and walk around, if everything goes right, finally you will come to below screen. 

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190928074719.png)

# Verify Your New APEX Instance
## Check Docker Images/Container

> Two docker containers will be running and both of them should be 'healthy'.

```
docker ps -a
```

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927130445.png)

> You will get four docker images. 

```
docker images
```

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927130654.png)


## Login APEX

> Now you can test if your new APEX is ready for you. Access the APEX admin url and test it. In my case, it will be similar as below:

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190926230438.png)

![](https://wangfanggang.oss-cn-shanghai.aliyuncs.com/images/20190927124836.png)

## Connect to Oracle Database
### Connect database in docker container

In my above example, the connection string likes as below: 

- **CDB:** `sqlplus sys/oracle123@47.98.247.100:1521/XE as sysdba`
- **PDB:** `sqlplus sys/oracle123@47.98.247.100:1521/XEPDB1 as sysdba`


### Connect database out of docker container

```
sqlplus sys/oracle@YOUR_REMOTE_SERVER_IP:YOUR_DB_PORT/XE as sysdba
sqlplus sys/oracle@YOUR_REMOTE_SERVER_IP:YOUR_DB_PORT/XEPDB1 as sysdba
```


## Review/Modify Configuration if necessary

- **DB Data File:** `/root/rapid-apex/oradata/`
- **ORDS config file:** `/root/rapid-apex/oracle-ords/`


# The End

> Now you are free from APEX installation and are able to quickly deploy a test environment with different version of APEX/ORDS. 
> If you like this, just star me!! [https://github.com/wfg2513148/rapid-apex](https://github.com/wfg2513148/rapid-apex)

