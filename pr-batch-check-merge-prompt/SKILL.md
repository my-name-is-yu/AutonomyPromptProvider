---
name: pr-batch-check-merge-prompt
description: Inspect a batch of GitHub pull requests, determine safe review and merge order, and draft a paste-ready prompt for a PR check/merge session. Use when the user wants to review, validate, queue, or merge multiple PRs after an autonomous implementation run.
---

# PR Batch Check/Merge Prompt

Turn a set of open pull requests into a safe, ordered PR check and merge
prompt.

Use this skill when the user wants:

- a batch of PRs checked after an autonomous implementation run
- dependency or stack order across multiple PRs
- CI, review, mergeability, and conflict triage
- a paste-ready prompt for a separate PR check/merge session
- merge execution guidance when the user explicitly grants merge authority

## Core Principle

Treat current repository evidence as authoritative.

Use this priority order:

1. live GitHub PR state, checks, reviews, mergeability, branch protection, and
   merge queue state
2. actual repository state, branches, and worktrees
3. PR body, linked issues, comments, and review threads
4. recent git history
5. docs and memory

Do not decide merge readiness from a stale implementation-session report alone.
Always refresh live PR state before drafting the prompt.

## Workflow

### 1. Resolve Repository and Authority

Start from the repository requested by the user. If none is provided, use the
current working directory.

Run:

```bash
git remote -v
git branch --show-current
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
gh pr list --state open --limit 100 \
  --json number,title,headRefName,baseRefName,isDraft,mergeStateStatus,url
```

Determine whether the user explicitly granted merge authority for this run.
If merge authority is unclear, generated prompts must stop at checks,
classification, and recommendations.

### 2. Build the PR Candidate Set

Read PR details before deciding order.

Use `gh pr view <number>` with relevant JSON fields for:

- PRs explicitly mentioned by the user
- PRs listed in an implementation handoff prompt
- PRs whose branches appear in a stack
- PRs that touch related files or close related issues
- PRs that are likely prerequisites or dependents

Suggested fields:

```bash
gh pr view <number> \
  --json number,title,body,state,isDraft,headRefName,baseRefName,mergeStateStatus,reviewDecision,statusCheckRollup,commits,files,closingIssuesReferences,url
```

Use GraphQL or GitHub UI tooling when unresolved review threads or merge queue
details matter and the local `gh pr view` output is insufficient.

### 3. Classify Each PR

Classify each PR as:

- `ready-to-merge`: non-draft, required checks passing, review state acceptable,
  mergeable against the current intended base, and no unresolved material
  blockers
- `ready-after-prerequisite`: stacked PR whose prerequisite must merge first
- `needs-rebase-or-retarget`: base branch or default-branch compatibility must
  be refreshed before checks are meaningful
- `needs-fix`: failing checks, unresolved material review comments, conflicts,
  or acceptance gaps
- `blocked`: missing permissions, ambiguous stack order, external approval,
  branch protection, merge queue state, or unclear ownership

For stacked PRs, checks against a prerequisite branch are provisional. Do not
mark a stacked PR `ready-to-merge` until the prerequisite PR has merged, the
dependent branch has been replayed or retargeted onto the latest default branch,
and checks have passed in that final context.

### 4. Determine Merge Order

Prefer this order:

1. prerequisite PRs
2. stacked dependents after replay onto the latest default branch
3. independent PRs that do not conflict
4. bundled PRs after verifying every linked issue is intentionally included

If two PRs touch the same risky surface, serialize them and re-check the second
after the first is merged or blocked.

Do not merge:

- draft PRs
- PRs with failing required checks
- PRs with unresolved material review threads
- stacked PRs still based on a prerequisite branch
- PRs whose mergeability or branch protection state is unknown
- PRs requiring external approval the session does not have

### 5. Draft the PR Check/Merge Prompt

The prompt must be paste-ready. Include:

- repository path and repository name
- default branch
- merge authority status
- target PR list
- stack/dependency order
- per-PR checks to run
- classification rules
- explicit stop conditions
- merge commands only when merge authority is explicit; omit merge commands
  entirely when authority is not granted
- final-report format

## Prompt Template

Use this template and fill in repository-specific details.

```md
Check this PR batch for `<REPO>` and merge only if merge authority is explicit
in this prompt.

Repository: <REPO_PATH>
Default branch: <DEFAULT_BRANCH>
Merge authority: <explicitly granted | not granted>

Startup checks:
- `git fetch origin`
- `gh pr list --state open --limit 100`
- For each target PR:
  - `gh pr view <number> --json number,title,body,state,isDraft,headRefName,baseRefName,mergeStateStatus,reviewDecision,statusCheckRollup,commits,files,closingIssuesReferences,url`
  - `gh pr checks <number>`
- If review-thread state, merge queue state, or branch protection is unclear,
  use GitHub GraphQL or the GitHub UI before deciding readiness.

Target PRs:
- #<PR1>: <title> | mode: <independent | stacked | bundled> | base: <branch>
- #<PR2>: <title> | mode: <independent | stacked | bundled> | base: <branch>
- #<PR3>: <title> | mode: <independent | stacked | bundled> | base: <branch>

Classification:
- `ready-to-merge`: non-draft, required checks passing, review state acceptable,
  mergeable against the current intended base, and no unresolved material
  blockers.
- `ready-after-prerequisite`: stacked PR waiting for a prerequisite PR.
- `needs-rebase-or-retarget`: checks are stale because the base branch or
  default branch changed.
- `needs-fix`: failing checks, unresolved material review comments, conflicts,
  or acceptance gaps.
- `blocked`: missing permissions, external approval, ambiguous stack order,
  branch protection, merge queue state, or unclear ownership.

Stacked PR rules:
- Treat checks on a stacked PR as provisional while it is based on another PR
  branch.
- Merge or block the prerequisite first.
- After a prerequisite merges, replay the dependent branch onto the latest
  `<DEFAULT_BRANCH>` or retarget it as the repository workflow requires.
- Re-run checks in the final default-branch context before marking the dependent
  PR merge-ready.
- Do not merge a dependent PR solely because it passed against a prerequisite
  branch.

Merge policy:
- If merge authority is not explicitly granted, do not merge anything. Stop
  after classification and recommendations. Do not include merge commands in
  the generated prompt.
- If merge authority is explicitly granted, merge only PRs classified
  `ready-to-merge`.
- If merge authority is explicitly granted, add an `Authorized merge commands`
  section using the repository's normal merge method. If no method is specified
  and squash merge is allowed, generate one command per ready PR using the
  repository's squash-merge command.
- After each merge, refresh PR state before evaluating the next PR.
- If a PR fails checks, has unresolved material reviews, is draft, conflicts,
  or has unknown mergeability, do not merge it.

Final report:
- PRs merged
- PRs not merged and reasons
- checks and review state observed
- stacked PRs replayed or still waiting
- follow-up fixes needed
- decisions needing human judgment
```

## Output Requirements

Return:

1. PR order and classification
2. material blockers
3. the paste-ready PR check/merge prompt

## Safety Notes

- Creating a prompt is not approval to merge.
- Merge authority must be explicit in the current user request or in the
  generated prompt's stated authority line.
- Never merge when branch protection, review state, required checks, merge queue
  state, or stack order is unclear.
