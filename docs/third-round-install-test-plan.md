# Third Round Real Install Test Plan

This plan expands coverage into APEX 22.x and older legacy APEX generations.
It is intentionally limited to profiles that the current installer can route
without introducing a new installer family.

## Acceptance Criteria

- The selected profile passes `bin/rapid-apex preflight`.
- `bin/rapid-apex e2e --profile <profile> --destroy-after --purge-data`
  completes without manual installation steps.
- Browser login succeeds with workspace `demo`, username `demo`, password
  `demo`.
- A new APEX application is created and opened in a real browser.
- The generated application accepts `demo/demo` and renders its Home page.
- Evidence screenshots and final URLs are recorded.
- Test containers, networks, and generated data are cleaned after each run.

## Matrix

| Priority | Database | APEX | ORDS | Profile | Coverage |
| --- | --- | --- | --- | --- | --- |
| T0 | 26ai Free | 22.2 | 22.x | `profiles/26ai-apex222-ords22.env` | First official-image ORDS family and APEX 22 coverage. |
| T1 | 19c BYOL | 22.1 | 23.x | `profiles/19c-apex221-ords23.env` | Enterprise database with APEX 22 and ORDS 23. |
| T2 | 18c XE | 18.2 | 18.4 | `profiles/18c-apex182-ords184.env` | Older legacy APEX/ORDS generation. |
| T3 | 18c XE | 5.1.4 | 3.0.12 | `profiles/18c-apex514-ords3012.env` | Oldest cataloged APEX and ORDS generation. |

## Execution Order

Run modern official-image profiles first, then legacy profiles:

1. T0: `profiles/26ai-apex222-ords22.env`
2. T1: `profiles/19c-apex221-ords23.env`
3. T2: `profiles/18c-apex182-ords184.env`
4. T3: `profiles/18c-apex514-ords3012.env`

## Command Template

```bash
bin/rapid-apex e2e --profile <profile> --destroy-after --purge-data
```

## Results

| Priority | Status | Evidence | Notes |
| --- | --- | --- | --- |
| T0 | Passed | `/u01/apex_demo/rapid-apex-third-round-20260603/.rapid-apex/evidence/apex222-26ai-lab/application-home.png` | 26ai Free/APEX 22.2/ORDS 22.4.0 completed on OCI; cleanup confirmed. |
| T1 | Passed | `/u01/apex_demo/rapid-apex-third-round-20260603/.rapid-apex/evidence/apex221-19c-lab/application-home.png` | 19c BYOL/APEX 22.1/ORDS 23.4.0 completed on OCI; cleanup confirmed. |
| T2 | Passed | `/u01/apex_demo/rapid-apex-third-round-20260603/.rapid-apex/evidence/apex182-xe18c-lab/application-home.png` | APEX 18.2 requires advancing the old create-application type step; cleanup confirmed. |
| T3 | Passed | `/u01/apex_demo/rapid-apex-third-round-20260603/.rapid-apex/evidence/apex514-xe18c-lab/application-home.png` | ORDS 3.0.12 uses the hyphenated media filename; APEX 5.1 needs create confirmation and generated-app `Log In` handling; cleanup confirmed. |

## Execution Host

Real e2e validation was run on the APEX Chinese community OCI Docker host in an
isolated directory:

```text
/u01/apex_demo/rapid-apex-third-round-20260603
```

The host's existing `oracle26` container and nginx configuration were left
untouched. Each test used `--destroy-after --purge-data`; after each run, the
lab containers, lab networks, and generated lab data directory were gone, with
only the pre-existing `oracle26` container still running.

## Findings

- APEX 18.2 has a create-application type selection page before the application
  name form; browser smoke advances that page with `Next`.
- APEX 5.1 has a final create-application confirmation page; browser smoke now
  clicks `Create Application` before opening the generated application.
- APEX 5.1 generated applications use `Log In` on the login button.
- ORDS 3.0.12 media is published as `ords-3.0.12.263.15.32.zip`, not with a
  dotted `ords.3...` prefix.

## Known Constraints

- Enterprise Database profiles require Oracle Container Registry access and
  accepted BYOL image terms.
- Local Docker Desktop may not be running on the macOS workstation, so real e2e
  runs can use the OCI Docker host or another prepared Docker host.
