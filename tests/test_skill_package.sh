#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
SKILL_DIR="$ROOT_DIR/skills/rapid-apex"
SKILL_MD="$SKILL_DIR/SKILL.md"
OPENAI_YAML="$SKILL_DIR/agents/openai.yaml"

if [[ ! -f "$SKILL_MD" ]]; then
  echo "expected Rapid-APEX skill file: skills/rapid-apex/SKILL.md" >&2
  exit 1
fi

if [[ ! -f "$OPENAI_YAML" ]]; then
  echo "expected Rapid-APEX skill metadata: skills/rapid-apex/agents/openai.yaml" >&2
  exit 1
fi

grep -qx -- "---" <(sed -n '1p' "$SKILL_MD")
grep -qx "name: rapid-apex" "$SKILL_MD"
grep -q "description: Rapid-APEX repository workflow skill" "$SKILL_MD"

if grep -q "TODO\\|\\[TODO" "$SKILL_MD" "$OPENAI_YAML"; then
  echo "skill package must not contain template TODO placeholders" >&2
  exit 1
fi

grep -q "bin/rapid-apex" "$SKILL_MD"
grep -q "profiles/profile-matrix.tsv" "$SKILL_MD"
grep -q "generate-profile -> validate -> plan or install" "$SKILL_MD"
grep -q "bash tests/test_skill_package.sh" "$SKILL_MD"
grep -q "git fetch --all --tags --prune" "$SKILL_MD"
grep -q "gh release view vX.Y.Z" "$SKILL_MD"

grep -q 'display_name: "Rapid-APEX"' "$OPENAI_YAML"
grep -q 'default_prompt: "Use $rapid-apex' "$OPENAI_YAML"

echo "Rapid-APEX skill package guard passed"
