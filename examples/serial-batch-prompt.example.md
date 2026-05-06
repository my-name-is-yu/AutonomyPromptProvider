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

Core policy:

- Prefer real code, tests, and CLI output over docs or memory.
- Use one issue, one branch, and one PR by default.
- Work inside one batch worktree.
- Open ready PRs.
- Merge only if the user explicitly granted merge authority for this run.
- Record decisions and blockers in `tmp/autonomous-issue-run-status.md`.

Per-issue workflow:

1. Run `git fetch origin && git switch --detach origin/main`.
2. Read the issue with `gh issue view <number>`.
3. Create a branch with `git switch -c codex/issue-<number>-<short-name>`.
4. Implement, test, review, commit, push, and open a ready PR.
5. Inspect checks with `gh pr checks --watch` when available.
6. Merge only if merge authority was explicit.
