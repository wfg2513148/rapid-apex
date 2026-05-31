# Rapid-APEX

[English](https://github.com/wfg2513148/rapid-apex) | [中文](https://github.com/wfg2513148/rapid-apex/blob/master/CN.md)

Rapid-APEX is an MIT-licensed open-source toolkit for quickly provisioning reproducible Oracle Database, Oracle APEX, and ORDS environments with Docker.

It is designed for Oracle APEX developers, trainers, consultants, and maintainers who need disposable test environments across different APEX and ORDS versions for learning, demos, upgrade testing, troubleshooting, and extension development.

> Project status: Rapid-APEX is being refreshed as a maintainer-led open-source project. The original automation supports Oracle Database XE 18c with multiple APEX and ORDS versions. The current roadmap focuses on modernizing the Docker workflow, adding validation, and supporting newer Oracle APEX and ORDS releases.

## Why Rapid-APEX exists

Setting up Oracle Database, Oracle APEX, and ORDS manually can be time-consuming and error-prone, especially when developers need to compare versions, reproduce issues, or prepare temporary training environments.

Rapid-APEX provides a reproducible Docker-based workflow so developers can focus on building and validating APEX applications instead of repeatedly assembling infrastructure by hand.

## Supported Product List

Current legacy automation supports:

- **Oracle Database:** XE 18c
- **Oracle APEX:** 19.2, 19.1, 18.2, 18.1, 5.1.4, 5.0.4
- **Oracle ORDS:** 19.2, 18.4, 18.2, 18.1, 3.0.12

## Maintainer Roadmap

Rapid-APEX is being refreshed to better serve the Oracle APEX developer community.

Planned improvements:

- Add support for recent Oracle APEX, ORDS, and Oracle Database versions
- Modernize Docker build scripts and runtime configuration
- Add GitHub Actions validation for shell scripts and Dockerfiles
- Improve installation documentation and troubleshooting guides
- Provide reproducible examples for APEX training, demos, and extension development
- Review legacy scripts for security, portability, and maintainability
- Create a clearer contribution path for other Oracle APEX developers

## Create Your New APEX Instance

### Get Installation Commands

Visit the Rapid-APEX generator:

<https://apex.oracle.com/pls/apex/f?p=75079:RAPID-APEX>

Click **Generate New APEX Instance**.

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190926221241.png)

### Base Information Collection

In the popup dialog, enter your **remote machine IP address**, **installation path**, and **OS version**.

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190926222346.png)

### Database Information Collection

Complete the database information collection step.

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190929131529.png)

Currently **Oracle Database XE 18c** is supported by the legacy automation.

Three download options are supported:

1. **Quick selection**: download installation files from the default online storage, `AWS S3 (East Asia)`.
2. **Provide a valid full download URL**: for example, `https://mybucket.s3.ap-northeast-1.amazonaws.com/oracle-database-xe-18c-1.0-1.x86_64.rpm`.
3. **Provide a valid local file path**: for example, `/root/oracle-database-xe-18c-1.0-1.x86_64.rpm`.

### APEX Information Collection

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190929131648.png)

### ORDS Information Collection

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190929131726.png)

### Finish

After the generator completes, copy the generated commands, paste them into a terminal on your target server, and press **Enter** to start the installation process.

You can also click **Finish** in the top-right corner of the page to save your configuration.

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190927130215.png)

## Install Your New APEX Instance

### Execute Installation Commands

Copy the generated commands and paste them into a terminal window on your remote server.

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190926223113.png)

The installation process may take **30 minutes to several hours** because it downloads installation media, builds Docker images for the database and ORDS, and starts the containers automatically.

If everything goes well, you will see a result similar to the following screenshot.

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190928074719.png)

## Verify Your New APEX Instance

### Check Docker Images and Containers

Two Docker containers should be running and both should be healthy.

```bash
docker ps -a
```

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190927130445.png)

You should also see four Docker images.

```bash
docker images
```

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190927130654.png)

### Login to APEX

Access the APEX administrator URL and verify that the environment is ready.

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190926230438.png)

![](https://oracle-apex-bucket.s3-ap-northeast-1.amazonaws.com/images/20190927124836.png)

### Connect to Oracle Database

#### Connect to the database from inside the Docker container

Example connection strings:

- **CDB:** `sqlplus sys/<db-password>@YOUR_REMOTE_SERVER_IP:1521/XE as sysdba`
- **PDB:** `sqlplus sys/<db-password>@YOUR_REMOTE_SERVER_IP:1521/XEPDB1 as sysdba`

#### Connect to the database from outside the Docker container

```bash
sqlplus sys/<db-password>@YOUR_REMOTE_SERVER_IP:YOUR_DB_PORT/XE as sysdba
sqlplus sys/<db-password>@YOUR_REMOTE_SERVER_IP:YOUR_DB_PORT/XEPDB1 as sysdba
```

### Review or Modify Configuration

- **DB data files:** `/root/rapid-apex/oradata/`
- **ORDS configuration files:** `/root/rapid-apex/oracle-ords/`

## Contributing

Contributions are welcome, especially around newer Oracle APEX/ORDS support, Docker modernization, documentation, and validation workflows.

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

Rapid-APEX is released under the [MIT License](LICENSE).

## Maintainer

Rapid-APEX is maintained by [Kenny Wang](https://github.com/wfg2513148), who also publishes Oracle APEX technical content for the Chinese-speaking developer community.

If this project helps you, please consider starring the repository: <https://github.com/wfg2513148/rapid-apex>
