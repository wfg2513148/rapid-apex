---
name: rapid-apex
description: Rapid-APEX repository workflow skill for planning, validating, installing, testing, troubleshooting, and releasing reproducible Oracle Database, Oracle APEX, and ORDS Docker labs. Use when working in or against the rapid-apex repo, its bin/rapid-apex CLI, profiles, version matrix, Docker scripts, smoke or e2e validation, documentation, CI checks, or release flow.
---

# Rapid-APEX

## Overview

Use this skill to work on the Rapid-APEX repository without drifting back to
legacy wizard or ad hoc Docker workflows. Treat `bin/rapid-apex`, reusable
`profiles/*.env`, and repo tests as the source of truth.

## Repository Facts

- Keep the project focused on disposable Oracle APEX developer, demo,
  troubleshooting, and compatibility-test labs.
- Use `bin/rapid-apex` as the front door for lab planning and operation.
- Keep the active workflow as `generate-profile -> validate -> plan or install
  --dry-run -> preflight -> install -> status/logs -> smoke/browser-smoke ->
  e2e -> recover/destroy`.
- Prefer Oracle official Database and ORDS container images. Keep legacy
  Dockerfile paths as fallback support for older combinations.
- Default license policy is `demo`, which allows Oracle XE and Free editions.
  Require explicit `--license-policy byol` for 19c Enterprise and 26ai
  Enterprise profiles.
- Do not run full installs casually. They can take a long time, need Docker and
  Oracle media access, and may consume significant disk space.

## First Pass

1. Read `AGENTS.md`, `README.md`, `ROADMAP.md`, and `CONTRIBUTING.md` before
   non-trivial edits.
2. Inspect the current branch, latest remote state, and latest tag:

   ```bash
   git fetch --all --tags --prune
   git status --short --branch
   git log --oneline --decorate -5
   git tag --sort=-v:refname | head
   ```

3. For user-facing workflow changes, update `README.md` and `CN.md` together.
4. Keep edits surgical. Do not rewrite legacy scripts unless the task explicitly
   asks for a migration.

## Common Tasks

### Plan a Lab

Use the CLI to prove the selected versions and plan before changing scripts:

```bash
bin/rapid-apex list-versions
bin/rapid-apex validate --db 26ai --apex 26.1 --ords 26
bin/rapid-apex plan --db 26ai --apex 26.1 --ords 26 --name apex261-lab
bin/rapid-apex generate-profile --db 26ai --apex 26.1 --ords 26 --output profiles/custom-26ai.env
```

For Enterprise Edition compatibility targets, include BYOL explicitly:

```bash
bin/rapid-apex plan --db 19c --apex 24.2 --ords 25 --license-policy byol
bin/rapid-apex plan --db 26ai-ee --apex 26.1 --ords 26 --license-policy byol
```

### Validate or Extend Profiles

- Put reusable version, port, and lab-name selections under `profiles/*.env`.
- Keep `profiles/profile-matrix.tsv` aligned with every committed profile.
- Run:

  ```bash
  bash tests/test_profile_matrix.sh
  bash tests/test_version_matrix.sh
  bash tests/test_rapid_apex_cli.sh
  ```

### Run a Lab

Use `e2e` as the normal complete path:

```bash
bin/rapid-apex e2e --profile profiles/26ai-apex261-ords26.env
```

Use `info`, `status`, and `logs` for inspection; use `recover` or `destroy`
only for the selected lab name/profile:

```bash
bin/rapid-apex info --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex status --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex logs --profile profiles/26ai-apex261-ords26.env
bin/rapid-apex recover --profile profiles/26ai-apex261-ords26.env --purge-data
```

### Troubleshoot

- Prefer `preflight` before long-running install debugging.
- Inspect selected profile values, ports, Docker image access, and Oracle media
  download access before changing install code.
- Redact passwords, tokens, registry credentials, wallets, and real connection
  strings from logs and issue text.
- Avoid destructive Docker cleanup unless the user explicitly asks for it. When
  cleanup is requested, scope it to the selected lab resources.

## Validation

Run lightweight checks before claiming changes are ready:

```bash
bash -n install.sh
bash -n run.sh
bash -n docker-xe/scripts/*.sh
bash -n docker-ords/scripts/*.sh
bash tests/test_version_matrix.sh
bash tests/test_rapid_apex_cli.sh
bash tests/test_profile_matrix.sh
bash tests/test_docs_install_workflow.sh
bash tests/test_skill_package.sh
```

If available, also run:

```bash
shellcheck -x --severity=warning \
  bin/rapid-apex \
  lib/rapid-apex-cli.sh \
  tools/version-matrix.sh \
  tests/test_version_matrix.sh \
  tests/test_rapid_apex_cli.sh \
  tests/test_profile_matrix.sh \
  tests/test_docs_install_workflow.sh \
  tests/test_skill_package.sh
hadolint docker-xe/Dockerfile docker-ords/Dockerfile
```

For full installation changes, record host OS, Docker version, selected
Database/APEX/ORDS versions, the command used with secrets redacted, and final
container health.

## Release Flow

When the user asks to publish, verify first, then commit, push, tag, and create
the GitHub Release. Use a new semver tag after the latest existing tag:

```bash
git diff --check
git status --short --branch
git tag --sort=-v:refname | head
```

After publishing, prove the release by checking tag and HEAD equality plus the
release metadata:

```bash
git rev-parse HEAD
git rev-parse "vX.Y.Z^{}"
gh release view vX.Y.Z --json tagName,name,isDraft,isPrerelease,url
```
