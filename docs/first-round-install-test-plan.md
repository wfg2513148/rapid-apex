# First Round Real Install Test Plan

This plan is for proving that Rapid-APEX can create a disposable APEX
developer environment that is usable in a real browser.

## Acceptance Criteria

- `bin/rapid-apex preflight` passes before installation.
- `bin/rapid-apex install` completes without manual installation steps.
- The generated ORDS endpoint opens in a real browser.
- Browser login succeeds with:
  - workspace: `demo`
  - username: `demo`
  - password: `demo`
- A new APEX application can be created from the browser.
- The new application can be opened and used from the browser.
- `bin/rapid-apex status`, `logs`, `smoke`, and `destroy` work for the lab name.

## First Combination

| Priority | Database | APEX | ORDS | Profile | Reason |
| --- | --- | --- | --- | --- | --- |
| P0 | 18c XE | 19.1 | 19.2 | `profiles/18c-apex191-ords192.env` | Exercises the legacy path most likely to work first. |
| P1 | 26ai Free | 26.1 | 26 | `profiles/26ai-apex261-ords26.env` | Exercises the modern official-image target. |
| P2 | 19c BYOL | 24.2 | 25 | `profiles/19c-apex242-ords25.env` | Exercises the common enterprise compatibility target. |
| P3 | 26ai Enterprise BYOL | 26.1 | 26 | `profiles/26ai-ee-apex261-ords26.env` | Exercises the newest Enterprise Edition official-image target. |

## Browser Flow

1. Open `http://localhost:<ords-port>/ords/`.
2. Navigate to the APEX workspace login page if ORDS redirects to a landing page.
3. Login with workspace `demo`, username `demo`, password `demo`.
4. Create a new application with a unique name, for example `RAPID_APEX_SMOKE_<timestamp>`.
5. Run or open the generated application from the builder.
6. Confirm the application page renders in the browser without server or console errors.

## Current Local Environment Result

As of 2026-05-31, shell checks pass, but real Docker execution is blocked by the
macOS host runtime:

```text
Docker daemon is not reachable. Start Docker Desktop or Colima, then retry.
```

Colima cannot start because the macOS host is missing `qemu-img`. Installing
`qemu` through Homebrew reached the source download step, but
`https://download.qemu.org/qemu-11.0.1.tar.xz` repeatedly failed or stalled from
this network.

## Current Remote OCI Result

The P0, P1, P2, and P3 combinations were executed on the OCI Docker host
`opc@140.245.120.204` using `/home/opc/rapid-apex-codex`:

| Priority | Result |
| --- | --- |
| P0 | Passed. Installed 18c XE, APEX 19.1, ORDS 19.2; browser login, app creation, app login/run, smoke, logs, status, and destroy were verified. |
| P1 | Passed. Installed 26ai Free, APEX 26.1, ORDS 26; browser workspace login, browser app creation, app login/run, status, smoke, and destroy were verified. |
| P2 | Passed. Installed 19c BYOL, APEX 24.2, ORDS 25; browser workspace login, browser app creation, app login/run, status, logs, smoke, and destroy were verified. |
| P3 | Passed. Installed 26ai Enterprise, APEX 26.1, ORDS 26.1.1; browser workspace login, app creation, app login/run, smoke, and cleanup were verified through scripted e2e. |

### P0: 18c XE / APEX 19.1 / ORDS 19.2

| Check | Result |
| --- | --- |
| `bash -n` script syntax checks | Passed |
| `tests/test_version_matrix.sh` | Passed |
| `tests/test_rapid_apex_cli.sh` | Passed |
| `bin/rapid-apex preflight --profile profiles/18c-apex191-ords192.env` | Passed |
| `bin/rapid-apex install --profile profiles/18c-apex191-ords192.env` | Installed 18c XE, APEX 19.1, demo workspace, and ORDS 19.2 |
| `bin/rapid-apex status --profile profiles/18c-apex191-ords192.env` | DB and ORDS containers healthy |
| `bin/rapid-apex logs --profile profiles/18c-apex191-ords192.env` | Passed; returned DB and ORDS logs |
| `bin/rapid-apex smoke --profile profiles/18c-apex191-ords192.env` | Passed with HTTP 302 from `/ords/` |
| Browser workspace login | Passed with workspace `demo`, user `demo` |
| Browser app creation | Passed; created `Application 100 - Rapid Apex Smoke 20260531` |
| Browser app login/run | Passed; app login accepted `demo/demo` and rendered Home |
| Scripted `bin/rapid-apex e2e --profile profiles/18c-apex191-ords192.env --destroy-after --purge-data` | Passed on 2026-06-01 after strict traditional `f?p` browser validation; created app `100` and rendered runtime Home as `demo` |
| `bin/rapid-apex destroy --profile profiles/18c-apex191-ords192.env` | Passed; removed generated DB and ORDS containers and network |

Evidence screenshots from the local Chrome run:

- `/tmp/rapid-apex-login-page.png`
- `/tmp/rapid-apex-builder-home.png`
- `/tmp/rapid-apex-create-app-before-submit.png`
- `/tmp/rapid-apex-create-app-after-submit.png`
- `/tmp/rapid-apex-run-app-100.png`
- Scripted browser evidence directory:
  `/home/opc/rapid-apex-codex/.rapid-apex/evidence/apex191-xe18c-lab/`
- Scripted e2e app run final URL:
  `http://localhost:32513/ords/demo/f?p=100:1:<session>`

Notes:

- The first ORDS build exposed a stale legacy Java base image
  `openjdk:8-jre-alpine`. The installer now uses
  `eclipse-temurin:8-jre-alpine` for the legacy ORDS path.
- `smoke` now checks the `/ords/` entrypoint HTTP status directly and accepts
  the normal APEX login redirect instead of following the full login redirect
  chain.

### P1: 26ai Free / APEX 26.1 / ORDS 26

| Check | Result |
| --- | --- |
| `bash -n` script syntax checks | Passed locally and on the OCI host |
| `tests/test_version_matrix.sh` | Passed locally and on the OCI host |
| `tests/test_rapid_apex_cli.sh` | Passed locally and on the OCI host |
| `git diff --check` | Passed locally |
| `bin/rapid-apex preflight --profile profiles/26ai-apex261-ords26.env` | Passed on the OCI host after moving the profile ports away from the existing long-running `oracle26` container |
| `bin/rapid-apex install --profile profiles/26ai-apex261-ords26.env` | Installed 26ai Free, APEX 26.1, demo workspace, and ORDS 26 using Oracle official container images |
| `bin/rapid-apex status --profile profiles/26ai-apex261-ords26.env` | DB container is healthy and ORDS container is running |
| `bin/rapid-apex smoke --profile profiles/26ai-apex261-ords26.env` | Passed with HTTP 302 from `/ords/` |
| Browser workspace login | Passed with workspace `demo`, user `demo`, password `demo`; landed on APEX 26.1 workspace home |
| Browser app creation | Passed; created `Application 103 - Rapid Apex Smoke 261` from App Builder |
| Browser app login/run | Passed; app login accepted `demo/demo` and rendered Home with `Rapid Apex Smoke 261` |
| `bin/rapid-apex destroy --profile profiles/26ai-apex261-ords26.env` | Passed; removed generated DB and ORDS containers and network |
| Scripted `bin/rapid-apex e2e --profile profiles/26ai-apex261-ords26.env --destroy-after --purge-data` | Passed on 2026-06-01; completed preflight, install, status, HTTP smoke, real browser app creation/login, and generated data cleanup |

Evidence:

- Browser app run screenshot: `/tmp/rapid-apex-p1-app103-home.png`
- Scripted browser evidence directory:
  `/home/opc/rapid-apex-codex/.rapid-apex/evidence/apex261-26ai-lab/`
- Browser app run final URL:
  `http://localhost:32514/ords/r/demo/rapid-apex-smoke-261/home?session=<session>`
- Scripted e2e app run final URL:
  `http://localhost:32514/ords/r/demo/rapid-apex-smoke-20260601051031/home?session=<session>`
- App Builder created application metadata:
  `DEMO / 103 / Rapid Apex Smoke 261 / RAPID-APEX-SMOKE-261`
- Scripted e2e created application metadata:
  `DEMO / 100 / Rapid Apex Smoke 20260601051031 / RAPID-APEX-SMOKE-20260601051031`

Notes:

- The official database image is
  `container-registry.oracle.com/database/free:latest`.
- The official ORDS image is pinned by the CLI to
  `container-registry.oracle.com/database/ords:26.1.1`.
- The existing remote `oracle26` container already owns host port `1521`, so
  the P1 profile uses `31522`, `35501`, and `32514`.
- APEX 26 builder/app login automation must wait for the APEX JavaScript submit
  runtime before clicking sign-in; direct raw form POST is not a valid browser
  equivalent.
- `destroy --purge-data` needs to handle container-owned files; the CLI now
  retries generated lab data cleanup with passwordless `sudo` when plain
  `rm -rf` cannot remove Docker volume files.

### P2: 19c BYOL / APEX 24.2 / ORDS 25

The original `enterprise_ru` image reference was not reachable after Oracle
Container Registry login, but the authorized 19c image reference is reachable:

```text
container-registry.oracle.com/database/enterprise:19.3.0.0
```

After updating the P2 image reference, preflight should validate
`container-registry.oracle.com/database/enterprise:19.3.0.0` before install.

```text
bin/rapid-apex preflight --profile profiles/19c-apex242-ords25.env
```

The previous blocker is replaced by the remaining resource task: free enough
disk on the OCI Docker host to pull and run the 19c image.

After freeing completed P1 lab resources, P2 was executed end to end:

| Check | Result |
| --- | --- |
| `bin/rapid-apex preflight --profile profiles/19c-apex242-ords25.env` | Passed; Docker reachable, image reachable, and ports `31523`, `35502`, `32515` available |
| `bin/rapid-apex install --profile profiles/19c-apex242-ords25.env` | Installed 19c Enterprise image, APEX 24.2, demo workspace, and ORDS 25 path using the official ORDS image |
| `bin/rapid-apex status --profile profiles/19c-apex242-ords25.env` | DB container healthy and ORDS container running |
| `bin/rapid-apex smoke --profile profiles/19c-apex242-ords25.env` | Passed with HTTP 302 from `/ords/` |
| Database validation | Passed; `apex_release.version_no = 24.2.0`, workspace `DEMO`, user `DEMO` |
| Browser workspace login | Passed with workspace `demo`, user `demo`, password `demo`; landed on APEX 24.2 workspace home |
| Browser app creation | Passed; created `Application 100 - Rapid Apex Smoke 242` from App Builder |
| Browser app login/run | Passed; app login accepted `demo/demo` and rendered Home with `Rapid Apex Smoke 242` |
| Scripted `bin/rapid-apex e2e --profile profiles/19c-apex242-ords25.env` | Passed on 2026-06-01 after strict traditional `f?p` browser validation; created app `100`, opened runtime Home as `demo`, and generated data was cleaned up after verification |
| `bin/rapid-apex logs --profile profiles/19c-apex242-ords25.env` | Passed; returned DB and ORDS logs |
| `bin/rapid-apex destroy --profile profiles/19c-apex242-ords25.env` | Passed; removed generated DB and ORDS containers and network |

Evidence:

- Browser workspace login screenshot: `/tmp/rapid-apex-p2-builder-home.png`
- Browser create application screenshot: `/tmp/rapid-apex-p2-create-app-after.png`
- Browser app run screenshot: `/tmp/rapid-apex-p2-app100-home.png`
- Scripted browser evidence directory:
  `/home/opc/rapid-apex-codex/.rapid-apex/evidence/apex242-19c-lab/`
- Scripted e2e app run final URL:
  started from a traditional `f?p=100:1:<session>` URL and was redirected by APEX to
  `http://localhost:32515/ords/r/demo/rapid-apex-smoke-20260601134103/home?session=<session>`
- App Builder created application metadata:
  `DEMO / 100 / Rapid Apex Smoke 242 / RAPID-APEX-SMOKE-242`

Notes:

- The working 19c official image is
  `container-registry.oracle.com/database/enterprise:19.3.0.0`.
- The unreachable image reference
  `container-registry.oracle.com/database/enterprise_ru:latest-19` was replaced.
- Oracle Container Registry credentials were removed from the test host with
  `docker logout container-registry.oracle.com` after the image was pulled.

### P3: 26ai Enterprise BYOL / APEX 26.1 / ORDS 26

| Check | Result |
| --- | --- |
| `bin/rapid-apex preflight --profile profiles/26ai-ee-apex261-ords26.env` | Passed after Oracle Container Registry BYOL login; database image and ORDS image were reachable and ports `31525`, `35504`, `32517` were available |
| `bin/rapid-apex e2e --profile profiles/26ai-ee-apex261-ords26.env --destroy-after --purge-data` | Passed on the OCI host |
| Database image | `container-registry.oracle.com/database/enterprise:latest` |
| ORDS image | `container-registry.oracle.com/database/ords:26.1.1` |
| Database service | `ORCLPDB1` |
| HTTP smoke | Passed with HTTP 302 from `/ords/` |
| Browser workspace login | Passed with workspace `demo`, user `demo`, password `demo` |
| Browser app creation | Passed; created `Application 100 - Rapid Apex Smoke 20260601060007` |
| Browser app login/run | Passed; app login accepted `demo/demo` and rendered Home |
| Cleanup | Passed; generated containers, network, and lab data directory were removed |

Evidence:

- Scripted browser evidence directory:
  `/home/opc/rapid-apex-codex/.rapid-apex/evidence/apex261-26ai-ee-lab/`
- Scripted e2e app run final URL:
  `http://localhost:32517/ords/r/demo/rapid-apex-smoke-20260601060007/home?session=<session>`
- App Builder created application metadata:
  `DEMO / 100 / Rapid Apex Smoke 20260601060007 / RAPID-APEX-SMOKE-20260601060007`

Notes:

- Oracle Container Registry credentials were removed from the test host with
  `docker logout container-registry.oracle.com` after validation.
- After cleanup, only the pre-existing long-running `oracle26` container was
  left running on the OCI host.
