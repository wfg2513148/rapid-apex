# Rapid-APEX Maintainer Roadmap

This roadmap describes the current direction for refreshing Rapid-APEX as an open-source toolkit for reproducible Oracle APEX developer environments.

## 1. Modernize supported versions

- Add support for recent Oracle APEX releases
- Add support for recent ORDS releases
- Evaluate newer Oracle Database XE / Free base images and installation flows
- Keep legacy version support documented where practical

## 2. Improve automation quality

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
