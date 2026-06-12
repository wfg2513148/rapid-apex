#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"

if grep -Eq "git clone|brew install git|apt-get install .*git|yum install .*git" "$ROOT_DIR/README.md" "$ROOT_DIR/CN.md"; then
  echo "quickstart docs must not require Git for one-command installation" >&2
  exit 1
fi

grep -q "codeload.github.com/wfg2513148/rapid-apex/tar.gz" "$ROOT_DIR/README.md"
grep -q "codeload.github.com/wfg2513148/rapid-apex/tar.gz" "$ROOT_DIR/CN.md"

echo "documentation install workflow guard passed"
