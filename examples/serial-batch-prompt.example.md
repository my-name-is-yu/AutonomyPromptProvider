# Example Generated Prompt

Create a separate worktree from `/path/to/repo`, then implement the following
open issues in order.

Startup steps:

- In the base repository, run `git switch main && git pull --ff-only`.
- Run `git fetch origin`.
- Run `mkdir -p /path/to/repo-worktrees`.
- Create a batch worktree only if the intended path does not already exist:
  `git worktree add --detach /path/to/repo-worktrees/example-batch origin/main`.
- Run `cd /path/to/repo-worktrees/example-batch`.
- Re-check current state with `gh issue list --state open --limit 100` and
  `gh issue view <number>` for each target issue.

Target issues:

1. #123 example first issue
2. #124 example second issue
3. #125 example third issue

Execution plan:

- #123: independent PR, base `main`
- #124: stacked PR, base `codex/issue-123-example`, depends on #123
- #125: independent PR, base `main`

Core policy:

- Prefer real code, tests, and CLI output over docs or memory.
- Use one issue, one branch, and one PR by default.
- Work inside one batch worktree.
- Open ready PRs.
- Do not merge PRs in the implementation session.
- Record decisions and blockers in `tmp/autonomous-issue-run-status.md`.

Per-issue workflow:

1. Confirm the issue's execution mode and write it to the status file.
2. Read the issue with `gh issue view <number>`.
3. For #123 and #125, run `git fetch origin && git switch --detach origin/main`
   before creating the issue branch.
4. For #124, switch to `codex/issue-123-example` and create the dependent
   branch from that prerequisite branch.
5. Implement, test, review, commit, push, and open a ready PR.
6. For #124, open the PR against `codex/issue-123-example`, not `main`.
7. Inspect checks with `gh pr checks --watch` when available.
8. Do not merge. Add the PR to the final handoff prompt.

PR batch check/merge handoff prompt:

```text
Use `pr-batch-check-merge-prompt` if it is installed.

Repository: /path/to/repo
Default branch: main
Implementation status file: tmp/autonomous-issue-run-status.md

Review these PRs in dependency order:
- #201: example first issue | mode: independent | base: main
- #202: example second issue | mode: stacked | base: codex/issue-123-example |
  depends on: #201
- #203: example third issue | mode: independent | base: main

Check CI, review state, conflicts, stack order, and mergeability. Treat checks
for stacked PRs as provisional until the dependent PR is replayed onto the
latest default branch after prerequisite merges.

Do not merge anything unless the user explicitly grants merge authority for
this PR batch check/merge run.
```
