# Rapid-APEX Maintainer Roadmap

This roadmap tracks the current v1.2.x stabilization work for Rapid-APEX as an
open-source toolkit for reproducible Oracle APEX developer environments.

## Completed For v1.2.0

- Added `bin/rapid-apex` as the CLI front door for list, validate, plan,
  preflight, install, status, logs, smoke, browser-smoke, e2e, destroy,
  recover, and profile generation workflows.
- Added a version catalog for Database 18c, 19c, 26ai, and 26ai-ee; APEX
  5.0.4 through 26.1; and ORDS 21.x through 26.x.
- Added demo-policy license validation for XE/Free editions and explicit BYOL
  policy requirements for Enterprise Edition profiles.
- Added representative real-install validation for 9 profiles across legacy
  18c XE, 19c Enterprise BYOL, 26ai Free, and 26ai Enterprise BYOL.
- Added CI checks for shell syntax, version matrix tests, CLI tests,
  ShellCheck, and Dockerfile linting.

## Remaining v1.2.0 Work

- Keep evidence output stable by preserving `e2e-summary.json` for successful
  and failed e2e runs.
- Expand fake-run tests around failed cleanup, port conflicts, and retry
  behavior as new recovery cases are found.
- Refresh README and CN quickstart/troubleshooting content around the CLI-first
  workflow.
- Close or split broad GitHub issues after each concrete acceptance criterion
  is documented.

## Future Work

- Validate additional catalog combinations that are not covered by the 9
  representative profiles.
- Add more troubleshooting recipes for Oracle Registry access,
  disk pressure, and host Docker setup.
- Continue hardening legacy scripts where they affect supported profile flows,
  without rewriting the historical XE 18c path wholesale.
- Add contribution issues for small, reviewable documentation and validation
  improvements.

## Long-Term Direction

Rapid-APEX should remain a practical developer tool for Oracle APEX maintainers,
consultants, trainers, and community contributors who need repeatable local or
server-based APEX environments for testing, demos, troubleshooting, and upgrade
planning.
