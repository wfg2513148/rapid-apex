# Rapid-APEX Maintainer Roadmap

This roadmap describes the current direction for refreshing Rapid-APEX as an open-source toolkit for reproducible Oracle APEX developer environments.

## 1. Modernize supported versions

- Add support for Oracle Database 19c Enterprise, 26ai Free, and 26ai Enterprise profiles
- Add support for ORDS 20.x, 21.x, 22.x, 23.x, 24.x, 25.x, and 26.x profiles
- Add support for APEX 20.1, 20.2, 21.1, 21.2, 22.1, 22.2, 23.1, 23.2, 24.1, 24.2, and 26.1 profiles
- Evaluate newer Oracle Database XE / Free base images and installation flows
- Keep legacy version support documented where practical

## 2. Improve automation quality

- Promote `bin/rapid-apex` as the one-stop CLI for list, validate, plan, install, status, logs, and destroy workflows
- Keep default demo-policy database installer support limited to Oracle XE or Free editions
- Require explicit BYOL acknowledgement for Enterprise Edition compatibility profiles
- Harden shell scripts with stricter error handling
- Reduce implicit assumptions about paths, ports, and host operating systems
- Improve Docker build reproducibility
- Add validation for Dockerfiles and shell scripts

## 3. Improve documentation

- Refresh the quickstart guide
- Add troubleshooting notes for common Docker and Oracle installation failures
- Document version compatibility and known limitations
- Add examples for training, demos, and upgrade-path testing

## 4. Build a clearer contribution path

- Maintain a contribution guide
- Label good first issues
- Keep roadmap items visible as GitHub issues
- Prefer small, reviewable pull requests

## 5. Long-term direction

The long-term goal is to make Rapid-APEX a practical developer tool for Oracle APEX maintainers, consultants, trainers, and community contributors who need repeatable local or server-based APEX environments.
