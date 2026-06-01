# Repository Agent Guide

## Purpose

- Rapid-APEX helps Oracle APEX developers quickly provision reproducible Oracle Database, Oracle APEX, and ORDS test environments.
- The main use case is compatibility testing across different Database, APEX, and ORDS versions for upgrades, new features, demos, training, troubleshooting, and extension development.
- Keep the project focused on disposable developer/test environments, not production-grade Oracle operations.

## Repository Model

- This is a small Docker-and-shell automation repository.
- Top-level scripts are the user entrypoints:
  - `run.sh` performs host environment checks, obtains the repository when needed, and invokes `install.sh`.
  - `install.sh` downloads installation media, builds Docker images, starts containers, installs APEX, and configures ORDS.
- `docker-xe/` owns the Oracle Database XE/APEX image build and database container scripts.
- `docker-ords/` owns the ORDS image build and ORDS container startup scripts.
- `bin/rapid-apex` is the new CLI front door for one-stop APEX lab planning and installation.
- `profiles/` stores reusable version/port/name selections.
- `.github/workflows/validation.yml` is the CI validation entrypoint.
- Documentation is user-facing and maintainer-facing:
  - `README.md` is the primary English overview and quickstart.
  - `CN.md` is the Chinese overview.
  - `ROADMAP.md` tracks modernization direction.
  - `CONTRIBUTING.md` describes contribution and validation expectations.

## Current Baseline

- The version catalog lives in `tools/version-matrix.sh`.
- Database versions tracked by the catalog are 18c, 19c, and 26ai.
- The default database license policy is `demo`, which allows Oracle XE and Free editions. Database 19c is a first-class compatibility target but requires explicit `--license-policy byol`.
- Prefer Oracle official container images from Oracle Container Registry for Database and ORDS. Use repository Dockerfile builds only as a fallback for legacy combinations without an official image path.
- APEX versions tracked by the catalog are 5.0.4, 5.1.4, 18.1, 18.2, 19.1, 19.2, 20.1, 20.2, 21.1, 21.2, 22.1, 22.2, 23.1, 23.2, 24.1, 24.2, and 26.1.
- ORDS versions tracked by the catalog are 3.0.12, 18.1, 18.2, 18.4, 19.2, 20.x, 21.x, 22.x, 23.x, 24.x, 25.x, and 26.x.
- Legacy automation still targets the original Oracle Database XE 18c path.
- Treat this baseline as historical compatibility support unless a task explicitly updates the supported version matrix.

## Working Norms

- Read this file, `README.md`, `ROADMAP.md`, and `CONTRIBUTING.md` before making non-trivial changes.
- Keep changes small and directly tied to the requested behavior.
- Do not rewrite legacy scripts wholesale unless the task explicitly asks for a migration.
- Preserve the ability to run legacy XE 18c/APEX 19.x/ORDS 19.x flows while adding modern flows, unless an explicit breaking change is approved.
- Prefer additive version profiles or clearly named scripts over hidden behavior changes.
- When changing user-facing workflow, update `README.md` and `CN.md` together where practical.

## Safety Rules

- Never commit Oracle installation media, generated Docker volumes, database data files, logs with secrets, wallets, passwords, private keys, tokens, or real connection strings.
- Do not print real passwords or tokens in logs. Redact sensitive values in status output.
- Be careful with Docker commands that remove containers, images, networks, or volumes. Ask before destructive cleanup unless the user explicitly requested it.
- Avoid running a full install by default. It can take a long time, consumes significant disk/CPU, and may require Oracle-licensed installation media.
- Do not assume Oracle media can be redistributed through this repository.

## Shell And Docker Style

- Use `#!/usr/bin/env bash` for Bash scripts and `#!/bin/sh` only for POSIX/Alpine scripts that must run without Bash.
- New or substantially edited shell scripts should use strict mode where compatible: `set -euo pipefail` for Bash, and `set -eu` for POSIX `sh`.
- Quote variable expansions unless word splitting is intentional.
- Keep functions small and name them with lowercase snake_case.
- Make repeated operations idempotent where possible, especially Docker network/container setup.
- Prefer explicit validation and actionable error messages before long-running Docker or download steps.

## Validation

Run the lightweight checks before claiming shell or Docker-related changes are complete:

```bash
bash -n install.sh
bash -n run.sh
bash -n docker-xe/scripts/*.sh
bash -n docker-ords/scripts/*.sh
bash tests/test_version_matrix.sh
bash tests/test_rapid_apex_cli.sh
```

If available locally, also run:

```bash
shellcheck install.sh run.sh docker-xe/scripts/*.sh docker-ords/scripts/*.sh
hadolint docker-xe/Dockerfile docker-ords/Dockerfile
```

For documentation-only changes, at minimum inspect the rendered Markdown or run a Markdown linter if one is available.

For full installation changes, record the tested host OS, Docker version, selected Database/APEX/ORDS versions, command used with secrets redacted, and the final container health status.

## Upgrade Directions

Prefer these incremental work streams:

1. Script hardening: strict mode, quoting, idempotent Docker network/container creation, clearer errors, safer logging, and password redaction.
2. Version matrix: introduce explicit Database/APEX/ORDS version profiles instead of positional-argument-only configuration.
3. Modern Database support: add Oracle Database Free / AI Database Free container-based flows alongside legacy XE 18c.
4. Modern APEX support: add current supported APEX releases and document compatibility expectations.
5. Modern ORDS support: migrate ORDS image/runtime scripts to the current ORDS CLI and Java requirements.
6. Validation: expand CI with shellcheck, Dockerfile linting, and smoke tests that do not require Oracle installation media.
7. Documentation: refresh quickstart, troubleshooting, version compatibility, and upgrade-testing recipes.

## Definition Of Done

- The requested behavior is implemented or the analysis outcome is documented.
- Relevant syntax/static checks were run and reported.
- User-facing docs are updated when workflow, defaults, or supported versions change.
- No secrets, installation media, generated data files, or bulky artifacts are committed.
