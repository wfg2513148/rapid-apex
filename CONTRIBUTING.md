# Contributing to Rapid-APEX

Thank you for your interest in contributing to Rapid-APEX.

Rapid-APEX is a small maintainer-led open-source project for Oracle APEX developers who need reproducible Oracle Database, APEX, and ORDS environments with Docker.

## Areas where contributions are welcome

High-value contribution areas include:

- Support for newer Oracle APEX releases
- Support for newer ORDS releases
- Support for newer Oracle Database XE / Free versions
- Updates to `tools/version-matrix.sh` and `docs/version-support.md` when version support changes
- Dockerfile modernization and hardening
- Shell script portability and error handling
- GitHub Actions validation
- Troubleshooting documentation
- Reproducible examples for training, demos, and upgrade testing

## Development guidelines

Before opening a pull request:

1. Keep changes focused and easy to review.
2. Avoid committing Oracle installation media, secrets, credentials, or generated large files.
3. Test shell changes in a disposable environment when possible.
4. Document any version-specific behavior for Oracle Database, APEX, or ORDS.
5. Update the README when the user-facing workflow changes.

## Validation checklist

For script and Docker-related changes, please include as many of the following checks as possible:

```bash
bash -n install.sh
bash -n run.sh
bash -n docker-xe/scripts/*.sh
bash -n docker-ords/scripts/*.sh
bash tests/test_version_matrix.sh
bash tests/test_rapid_apex_cli.sh
bash tests/test_profile_matrix.sh
bash tests/test_docs_install_workflow.sh
```

If available locally, also run:

```bash
shellcheck install.sh run.sh docker-xe/scripts/*.sh docker-ords/scripts/*.sh
hadolint docker-xe/Dockerfile docker-ords/Dockerfile
```

## Reporting issues

When reporting an issue, please include:

- Host operating system and version
- Docker version
- Oracle Database / APEX / ORDS versions selected
- Installation command used, with secrets redacted
- Relevant logs or error messages
- Whether the failure is reproducible in a fresh directory

## Security

Do not include passwords, private keys, tokens, connection strings, or other credentials in issues, pull requests, screenshots, or logs.
