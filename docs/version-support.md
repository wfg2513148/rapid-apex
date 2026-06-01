# Version Support

Rapid-APEX exists to create disposable Oracle APEX test environments for
upgrade, compatibility, training, demo, and feature validation.

## Supported Version Catalog

The repository version catalog is maintained in `tools/version-matrix.sh`.

### Oracle Database

- 18c
- 19c
- 26ai
- 26ai-ee

### Oracle APEX

- 5.0.4
- 5.1.4
- 18.1
- 18.2
- 19.1
- 19.2
- 20.1
- 20.2
- 21.1
- 21.2
- 22.1
- 22.2
- 23.1
- 23.2
- 24.1
- 24.2
- 26.1

### Oracle REST Data Services

- 3.0.12
- 18.1
- 18.2
- 18.4
- 19.2
- 20.x
- 21.x
- 22.x
- 23.x
- 24.x
- 25.x
- 26.x

## Installer Families

Rapid-APEX keeps legacy and modern installer families separate.

| Product | Versions | Family |
| --- | --- | --- |
| Database | 18c | `oracle-express-container` |
| Database | 19c, 26ai-ee | `oracle-enterprise-ru-container` |
| Database | 26ai | `oracle-free-container` |
| ORDS | 3.0.12, 18.x, 19.x, 20.x, 21.x | `legacy-simple` |
| ORDS | 22.x, 23.x, 24.x, 25.x, 26.x | `official-oracle-image` |

The legacy `install.sh` path still reflects the original XE 18c flow. New work
should add explicit code paths for Oracle official Database and ORDS images
instead of forcing newer versions through legacy assumptions.

## Official Image Policy

Prefer Oracle official container images from Oracle Container Registry:

- Database XE/Express: `container-registry.oracle.com/database/express`
- Database 19c Enterprise BYOL: `container-registry.oracle.com/database/enterprise:19.3.0.0`
- Database Free: `container-registry.oracle.com/database/free`
- Database 26ai Enterprise BYOL: `container-registry.oracle.com/database/enterprise:latest` by default, override with `--db-image` for a pinned authorized tag
- ORDS: `container-registry.oracle.com/database/ords`

Fallback Dockerfile builds should be used only when an exact legacy version is
not available as an official image and the requested media is available from an
approved download source.

ORDS official-image profiles use pinned major-version tags instead of `latest`.
Use `--ords-image-tag TAG` to select a different Oracle-published patch tag for
the requested ORDS major. Preflight validates that the selected ORDS image is
available locally or reachable from the registry before installation starts.

Rapid-APEX uses a `demo` database license policy by default, which allows XE and
Free editions. Enterprise Edition profiles require explicit BYOL acknowledgement:

```bash
bin/rapid-apex plan --db 19c --apex 24.2 --ords 25 --license-policy byol
bin/rapid-apex plan --db 26ai-ee --apex 26.1 --ords 26 --license-policy byol
```

## CLI

Use the CLI for new workflows:

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

Current `install` execution is enabled for the legacy 18c XE + ORDS
3/18/19/20/21 family and for modern official Database + ORDS image profiles.
Run with `--dry-run` to inspect validated plans, and run `preflight` before any
real installation attempt. Legacy and official-image installs create a `demo`
workspace and `demo` developer account with password `demo` for browser-based
validation. The `e2e` command runs the whole scripted path from preflight through
real browser application creation and login validation. Database 19c profiles
require Oracle Container Registry access to an accepted BYOL image before
preflight can pass.

## Media Source

The original scripts default to the historical public bucket. New automation
should allow a caller to set an OSS or private media base URL, for example:

```bash
RAPID_APEX_MEDIA_BASE_URL=https://example.oss-cn-shanghai.aliyuncs.com/
```

The repository must not commit Oracle installation media or private download
URLs that are not intended to be public.

## Validation

Run:

```bash
bash tests/test_version_matrix.sh
bash tests/test_rapid_apex_cli.sh
```

This verifies that the requested Database, APEX, and ORDS versions are
recognized and mapped to the expected installer families.
