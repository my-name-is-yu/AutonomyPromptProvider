#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_file="$repo_root/issue-autonomy-prompt/SKILL.md"

fail() {
  printf 'check-skill: %s\n' "$1" >&2
  exit 1
}

[[ -f "$skill_file" ]] || fail "missing issue-autonomy-prompt/SKILL.md"

grep -q '^name: issue-autonomy-prompt$' "$skill_file" \
  || fail "missing expected skill name"

grep -q 'Default worktree strategy' "$skill_file" \
  || fail "missing worktree strategy section"

grep -q 'Only when creating a new `<BATCH_WORKTREE_PATH>`' "$skill_file" \
  || fail "worktree creation must be conditional"

grep -q 'Merge only if the user explicitly requested merge authority' "$skill_file" \
  || fail "merge authority must be explicit"

old_skill="github-issue-autonomy-""planner"
product_name="Pul""Seed"
if grep -RInE "$old_skill|Codex/$product_name|$product_name" "$repo_root"; then
  fail "found old or personal naming"
fi

if ! python3 - "$repo_root" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
bad = []
for path in sorted(root.rglob("*")):
    if ".git" in path.parts or not path.is_file():
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for ch in text:
        code = ord(ch)
        if (
            0x3040 <= code <= 0x309F
            or 0x30A0 <= code <= 0x30FF
            or 0x3400 <= code <= 0x9FFF
        ):
            bad.append(str(path))
            break
if bad:
    print("\n".join(bad))
    sys.exit(1)
PY
then
  fail "found non-English Japanese text"
fi

unsafe_merge_a='CI green.*mer''ge'
unsafe_merge_b='LGTM.*mer''ge'
if grep -RInE "$unsafe_merge_a|$unsafe_merge_b" "$repo_root"; then
  fail "found unconditional merge wording"
fi

printf 'check-skill: ok\n'
