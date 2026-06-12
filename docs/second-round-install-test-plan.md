# Second Round Real Install Test Plan

This plan expands the v1.1.0 first-round validation to older and mid-generation
APEX/ORDS combinations. It is tracked by GitHub issue #6 and the `v1.2.0`
milestone.

## Acceptance Criteria

- The selected profile passes `bin/rapid-apex preflight`.
- `bin/rapid-apex e2e --profile <profile> --destroy-after --purge-data`
  completes without manual installation steps.
- The browser validation uses the traditional `f?p` path where possible.
- Browser login succeeds with workspace `demo`, username `demo`, password `demo`.
- A new APEX application is created and opened in a real browser.
- The generated application accepts `demo/demo` and renders its Home page.
- Evidence screenshots and final URLs are recorded.
- Test containers, networks, and generated data are cleaned after each run.

## Matrix

| Priority | Database | APEX | ORDS | Profile | Coverage |
| --- | --- | --- | --- | --- | --- |
| S1 | 18c XE | 21.2 | 21.x | `profiles/18c-apex212-ords21.env` | Legacy-simple ORDS family before official-image ORDS. |
| S2 | 26ai Free | 23.2 | 23.x | `profiles/26ai-apex232-ords23.env` | Modern free database with mid-generation APEX/ORDS official images. |
| S3 | 19c BYOL | 23.1 | 24.x | `profiles/19c-apex231-ords24.env` | Common enterprise database with APEX 23 and ORDS 24. |
| S4 | 26ai Free | 24.1 | 24.x | `profiles/26ai-apex241-ords24.env` | Modern free database with APEX 24.1 and ORDS 24. |

## Execution Order

Run the legacy profile first because it is the most likely to expose media and
APEX wizard differences:

1. S1: `profiles/18c-apex212-ords21.env`
2. S2: `profiles/26ai-apex232-ords23.env`
3. S3: `profiles/19c-apex231-ords24.env`
4. S4: `profiles/26ai-apex241-ords24.env`

## Command Template

```bash
bin/rapid-apex e2e --profile <profile> --destroy-after --purge-data
```

## Results

| Priority | Status | Evidence | Notes |
| --- | --- | --- | --- |
| S1 | Passed | `/tmp/rapid-apex-evidence/s1-pass-final/application-home.png` | `bin/rapid-apex e2e --profile profiles/18c-apex212-ords21.env --destroy-after --purge-data` completed on OCI with Database 18c XE, APEX 21.2, ORDS 21.4.2. Browser created app `100` from a traditional `f?p` entry flow and opened `.../rapid-apex-smoke-20260602025304/home`. |
| S2 | Passed | `/tmp/rapid-apex-evidence/s2-pass-final/application-home.png` | `bin/rapid-apex e2e --profile profiles/26ai-apex232-ords23.env --destroy-after --purge-data` completed on OCI with Database 26ai Free, APEX 23.2, ORDS 23.4.0. Browser created app `100` and opened `http://localhost:32522/ords/r/demo/rapid-apex-smoke-20260602055143/home?session=632801035529`. |
| S3 | Passed | `/tmp/rapid-apex-evidence/s3-pass-u01-final/application-home.png` | `bin/rapid-apex e2e --profile profiles/19c-apex231-ords24.env --destroy-after --purge-data` completed on the OCI host under `/u01/apex_demo/rapid-apex` with Database 19c Enterprise BYOL, APEX 23.1, ORDS 24.2.3. Browser created app `100` and opened `http://localhost:32523/ords/r/demo/rapid-apex-smoke-20260602095332/home?session=13992879690891`. Test containers, network, and lab data were purged after the run. |
| S4 | Passed | `/tmp/rapid-apex-evidence/s4-pass-u01-final/application-home.png` | `bin/rapid-apex e2e --profile profiles/26ai-apex241-ords24.env --destroy-after --purge-data` completed on the OCI host under `/u01/apex_demo/rapid-apex` with Database 26ai Free, APEX 24.1, ORDS 24.2.3. Browser created app `100` and opened `http://localhost:32524/ords/r/demo/rapid-apex-smoke-20260602110033/home?session=3639425266852`. Test containers, network, and lab data were purged after the run. |

## Findings From Legacy ORDS Media

- ORDS `21.x` cannot use placeholder media names; the installer now maps it to
  a concrete Oracle official downloadable zip file.
- Legacy ORDS media directories must keep only the selected `ords*.zip`; stale
  media can otherwise be picked up by Docker wildcard copies.
- Cached `apex/` directories must still receive refreshed `apex-install*`
  helper scripts before each run.

## Findings From S1

- Cached `apex/` directories must be tied to the selected APEX media; otherwise
  a previous APEX unzip can make a later profile install the wrong APEX version.
- APEX 21.2 plus ORDS 21 redirects runtime apps from traditional `f?p` URLs to
  friendly runtime URLs after entry. Browser validation now clears the App
  Builder cookies before opening the generated runtime app from
  `/ords/f?p=<APP_ID>:1`, avoiding builder-session redirect loops while still
  testing the traditional entry path.

## Findings From S2

- APEX 23.1+ media should use Oracle's official
  `https://download.oracle.com/otn_software/apex/apex_<version>.zip` URL.
- Official Database/ORDS profiles must fail immediately when APEX media download
  or unzip fails; command substitution previously hid that failure.
- Official ORDS images require `/opt/oracle/variables/conn_string.txt` with a
  `CONN_STRING=...` value and serve on container port `8181`.
- Official ORDS images resolve APEX under `/opt/oracle/apex/<APEX_VER>/`; the
  selected APEX export must be mounted at that versioned path.
- Official ORDS 23 needs the APEX gateway configured with
  `--gateway-mode direct --gateway-user APEX_PUBLIC_USER`; using
  `--db-user APEX_PUBLIC_USER` is rejected by ORDS 23 and leaves no pool
  mapping for APEX.
- Browser validation must derive the traditional `f?p` base URL from the final
  post-login page URL, because probing `/ords/apex` can otherwise make later
  App Builder URLs use the invalid `/ords/apex/f?p=...` shape.
- APEX application creation can land directly on the Application home page
  without leaving a visible `P1_STATUS`/`P56_STATUS` value. Browser validation
  now treats that page transition as successful completion.
- On this 36G OCI host, official Database/ORDS profiles can pass with 10 GiB
  free before install when selected media is removed after extraction and test
  containers/data are purged after each run.

## Findings From S3

- The OCI host's root filesystem is too small for repeated official Database
  image testing when Docker stores images under `/var/lib/docker`; real e2e
  runs now use `/u01/apex_demo/rapid-apex` for repository media, lab data,
  Playwright cache, and evidence.
- ORDS 24 official images do not expose the same `/entrypoint.sh` path used by
  ORDS 23. The installer now installs APEX from the database container and runs
  ORDS 24 with a repository-owned entry script.
- ORDS 24 proxied gateway mode creates `ORDS_PUBLIC_USER` during ORDS install,
  after the demo workspace may already exist. Browser validation now grants
  runtime proxy users after ORDS starts and restarts ORDS 24+ before smoke
  testing so the pool sees the grants.
- APEX 23.1's Create Application button is enabled by a keydown-driven dynamic
  action. Browser validation now types the app name through keyboard input,
  syncs the APEX item value, and lets the page's own create-button logic enable
  the action instead of force-submitting a disabled button.

## Findings From S4

- `container-registry.oracle.com/database/free:latest` currently reports itself
  as `Oracle AI Database 26ai Free` in `SYS.PRODUCT_COMPONENT_VERSION`.
  ORDS 24.x installers query `SYS.PRODUCT_COMPONENT_VERSION` with
  `product like 'Oracle Database%'`, which raises `ORA-01403` on 26ai Free.
- For disposable 26ai Free demo databases with ORDS 24.x, the installer now
  applies a compatibility view inside the demo PDB that maps the product label
  to `Oracle Database ...` before ORDS install. This keeps ORDS 24.2.3 install
  usable for the test matrix without changing the host or production database.
- APEX 24.1 on 26ai Free also needs `grant execute on sys.resolve_synonym to
  APEX_240100` followed by APEX's own `validate_apex.sql`; otherwise the APEX
  registry remains `INVALID` after installation.

## Known Constraints

- Enterprise Database profiles require Oracle Container Registry access and BYOL
  terms acceptance.
- The OCI Docker host currently has a long-running `oracle26` container; second
  round profiles use non-default host ports to avoid it.
- Local Docker Desktop is not running on the macOS workstation, so real e2e runs
  are executed on the OCI Docker host.
