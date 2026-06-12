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

Current `install` execution is enabled for the legacy 18c XE + ORDS
3/18/19/20/21 family and for modern official Database + ORDS image profiles.
Run with `--dry-run` to inspect validated plans, and run `preflight` before any
real installation attempt. Legacy and official-image installs create a `demo`
workspace and `demo` developer account with password `demo` for browser-based
validation. The `e2e` command runs the whole scripted path from preflight through
real browser application creation and login validation. Database 19c profiles
require Oracle Container Registry access to an accepted BYOL image before
preflight can pass.

### E2E Evidence Summary

Every real `e2e` run writes a machine-readable summary to:

```text
.rapid-apex/evidence/<lab-name>/e2e-summary.json
```

The summary records the selected profile, product versions, license policy,
host ports, selected Database/ORDS image references, ORDS URL, workspace/user
name, generated application metadata when browser validation succeeds, final
URL, screenshot paths, exit status, and cleanup status. Passwords and tokens
are not written to the summary.

Use `--evidence-dir DIR` when evidence should be written outside the default
repository-local `.rapid-apex/evidence/` path.

### Profile Generation And Recovery

`generate-profile` creates a reusable shell profile from a selected
Database/APEX/ORDS combination. It auto-selects the known default lab name,
ports, and Enterprise image/tag defaults for supported profile families.
Enterprise Database profiles still require explicit `--license-policy byol`.

`recover` is the scoped cleanup command for interrupted installs. It targets
only the selected lab name's containers and network, and with `--purge-data`
also removes generated lab data paths for that lab.

### Operational Troubleshooting

Use `preflight` before long-running installs. It checks Docker availability,
tries to install required tools and start Docker automatically on supported
hosts, checks selected image access, free disk for official-image profiles, and
host port availability.

| Area | Expected behavior | Recovery path |
| --- | --- | --- |
| Required tool setup | `preflight` attempts to install required tools such as Docker and start the Docker daemon with supported host tooling before reporting failure. | If automatic setup is unsupported or lacks privilege, install or start the reported tool with host-appropriate privileges before rerunning preflight. |
| BYOL registry access | Enterprise profiles validate the selected Database image locally or through the registry manifest. | Log in to Oracle Container Registry and accept the required image terms. |
| ORDS image tag | Official ORDS profiles validate the selected pinned tag. | Provide `--ords-image-tag TAG` when Oracle publishes a different patch tag for that ORDS major. |
| Media downloads | Downloads retry before failing and remove partial files on failure. | Check network access or use `--media-base URL` for a reachable mirror. |
| Port conflicts | `preflight` prints the occupied port and, where possible, the owning process/container. | Change profile ports or stop the selected conflicting lab/container. |
| Interrupted install | `recover` removes only `<name>_db`, `<name>_ords`, `<name>_network`, and selected lab data with `--purge-data`. | Run `bin/rapid-apex recover --profile <profile> --purge-data`. |
| Failed cleanup | `destroy`/`recover` reports residual containers, networks, and selected lab data paths. | Stop remaining resources, rerun recover, or remove the listed data path with appropriate permissions. |

## Real Install Coverage

The following profile families have passed scripted real-install validation with
`bin/rapid-apex e2e --profile <profile> --destroy-after --purge-data` on the
OCI Docker host recorded in the install test plans:

| Database | APEX | ORDS | Profiles |
| --- | --- | --- | --- |
| 18c XE | 5.1.4, 18.2, 19.1, 20.2, 21.2 | 3.0.12, 18.4, 19.2, 20.x, 21.x | `profiles/18c-*` |
| 26ai Free | 22.2, 23.2, 24.1, 26.1 | 22.x, 23.x, 24.x, 26.x | `profiles/26ai-*` |
| 19c Enterprise BYOL | 22.1, 23.1, 24.2 | 23.x, 24.x, 25.x | `profiles/19c-*` |
| 26ai Enterprise BYOL | 26.1 | 26.x | `profiles/26ai-ee-*` |

See `docs/first-round-install-test-plan.md`,
`docs/second-round-install-test-plan.md`, and
`docs/third-round-install-test-plan.md` for command logs, evidence paths, and
version-specific findings.

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
bash -n install.sh
bash -n run.sh
bash -n docker-xe/scripts/*.sh
bash -n docker-ords/scripts/*.sh
bash tests/test_version_matrix.sh
bash tests/test_rapid_apex_cli.sh
```

This verifies that the requested Database, APEX, and ORDS versions are
recognized and mapped to the expected installer families.

GitHub Actions also runs ShellCheck on the modern Bash entrypoints and test
scripts, plus Hadolint on both Dockerfiles. Legacy installer scripts remain
under `bash -n` syntax validation unless a task explicitly modernizes them.
