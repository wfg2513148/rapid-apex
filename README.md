# Rapid-APEX

[English](https://github.com/wfg2513148/rapid-apex) | [中文](https://github.com/wfg2513148/rapid-apex/blob/master/CN.md)

Rapid-APEX is an MIT-licensed open-source toolkit for quickly provisioning reproducible Oracle Database, Oracle APEX, and ORDS environments with Docker.

It is designed for Oracle APEX developers, trainers, consultants, and maintainers who need disposable test environments across different APEX and ORDS versions for learning, demos, upgrade testing, troubleshooting, and extension development.

> Project status: Rapid-APEX is in v1.2.0 stabilization. The CLI path can plan,
> install, validate, and clean up representative legacy and modern APEX lab
> profiles. The original online-generator flow is kept as historical legacy
> documentation.

## Why Rapid-APEX exists

Setting up Oracle Database, Oracle APEX, and ORDS manually can be time-consuming and error-prone, especially when developers need to compare versions, reproduce issues, or prepare temporary training environments.

Rapid-APEX provides a reproducible Docker-based workflow so developers can focus on building and validating APEX applications instead of repeatedly assembling infrastructure by hand.

## Supported Product List

Current version catalog supports:

- **Oracle Database:** XE 18c, 19c Enterprise, 26ai Free, 26ai Enterprise
- **Oracle APEX:** 26.1, 24.2, 24.1, 23.2, 23.1, 22.2, 22.1, 21.2, 21.1, 20.2, 20.1, 19.2, 19.1, 18.2, 18.1, 5.1.4, 5.0.4
- **Oracle ORDS:** 26.x, 25.x, 24.x, 23.x, 22.x, 21.x, 20.x, 19.2, 18.4, 18.2, 18.1, 3.0.12

The original installer path remains the legacy XE 18c flow. Newer database and
ORDS families are recognized by the version catalog and should be implemented
through explicit modern installer paths. See
[`docs/version-support.md`](docs/version-support.md).

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

## CLI Preview

The new CLI is being introduced as the stable front door for one-stop APEX lab
creation. It currently supports version discovery, profile generation and
validation, preflight checks, environment status/log helpers, cleanup/recovery,
dry-run installation plans, and scripted e2e evidence summaries.

```bash
bin/rapid-apex list-versions
bin/rapid-apex validate --db 26ai --apex 26.1 --ords 26
bin/rapid-apex plan --db 26ai --apex 26.1 --ords 26 --name apex261-lab
bin/rapid-apex generate-profile --db 26ai --apex 26.1 --ords 26 --output profiles/custom-26ai.env
bin/rapid-apex preflight --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex install --dry-run --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex status --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex logs --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex smoke --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex browser-smoke --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex e2e --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex destroy --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex recover --profile profiles/26ai-apex261-ords26.env
```

Database installs use the `demo` license policy by default, which allows Oracle
XE and Free editions. Enterprise Edition profiles are BYOL targets and require
explicit acknowledgement because the user must have valid Oracle license/terms:

```bash
bin/rapid-apex plan --db 19c --apex 24.2 --ords 25 --license-policy byol
bin/rapid-apex plan --db 26ai-ee --apex 26.1 --ords 26 --license-policy byol
```

`e2e` is the scripted end-to-end path: it runs preflight checks, installation,
container status, HTTP smoke validation, and a real browser flow that logs in to
the `demo` workspace, creates a new APEX application, and logs in to the
generated application with `demo/demo`. Browser evidence is written under
`.rapid-apex/evidence/<lab-name>/` by default, including an
`e2e-summary.json` file with versions, images, ports, final URL, screenshot
paths, status, and cleanup status. Add `--destroy-after` only when the lab
should be stopped after validation, and add `--purge-data` when the generated
lab data directory should also be removed.

Rapid-APEX prefers Oracle official container images from Oracle Container
Registry for Database and ORDS. The legacy Dockerfile build path remains as a
fallback for older combinations that do not have an official image path.
ORDS official-image plans use pinned major-version tags instead of `latest`;
use `--ords-image-tag TAG` when a lab needs a specific Oracle-published patch
tag for that ORDS major.
Enterprise Database image plans can also be overridden with `--db-image IMAGE`
when Oracle publishes a different authorized tag for the selected major version.

Full execution is currently enabled for the legacy 18c XE + ORDS 3/18/19/20/21
family and for modern official Database + ORDS image profiles. Legacy and
official-image installs create a `demo` workspace and `demo` developer account
with password `demo` for browser-based validation.

Validated real-install profiles include:

| Database | APEX | ORDS | Profile |
| --- | --- | --- | --- |
| 18c XE | 5.1.4, 18.2, 19.1, 20.2, 21.2 | 3.0.12, 18.4, 19.2, 20.x, 21.x | `profiles/18c-*` |
| 26ai Free | 22.2, 23.2, 24.1, 26.1 | 22.x, 23.x, 24.x, 26.x | `profiles/26ai-*` |
| 19c Enterprise BYOL | 22.1, 23.1, 24.2 | 23.x, 24.x, 25.x | `profiles/19c-*` |
| 26ai Enterprise BYOL | 26.1 | 26.x | `profiles/26ai-ee-*` |

## CLI Quickstart

For a demo-policy Oracle Database Free lab:

```bash
bin/rapid-apex generate-profile \
  --db 26ai \
  --apex 26.1 \
  --ords 26 \
  --output profiles/my-26ai-lab.env

bin/rapid-apex validate --profile profiles/my-26ai-lab.env
bin/rapid-apex preflight --profile profiles/my-26ai-lab.env
bin/rapid-apex install --profile profiles/my-26ai-lab.env
bin/rapid-apex e2e --profile profiles/my-26ai-lab.env
```

For a legacy 18c XE lab:

```bash
bin/rapid-apex generate-profile \
  --db 18c \
  --apex 19.1 \
  --ords 19.2 \
  --output profiles/my-18c-lab.env
```

For Enterprise Edition compatibility profiles, use BYOL only when you have
accepted the applicable Oracle license and registry terms:

```bash
bin/rapid-apex generate-profile \
  --db 19c \
  --apex 24.2 \
  --ords 25 \
  --license-policy byol \
  --output profiles/my-19c-lab.env

bin/rapid-apex generate-profile \
  --db 26ai-ee \
  --apex 26.1 \
  --ords 26 \
  --license-policy byol \
  --output profiles/my-26ai-ee-lab.env
```

If an installation fails partway through, clean only the selected lab resources:

```bash
bin/rapid-apex recover --profile profiles/my-26ai-lab.env --purge-data
```

`recover` is scoped to the selected lab name. It removes the matching
`<name>_db`, `<name>_ords`, and `<name>_network` resources and, with
`--purge-data`, generated lab data paths.

## Legacy Generator Path

The historical Rapid-APEX online generator remains documented below for users
who need the original XE 18c flow. New workflows should prefer
`bin/rapid-apex`.

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

The legacy automation path currently installs **Oracle Database XE 18c**.
Database 19c and 26ai are tracked in the version catalog for modernization work.

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
