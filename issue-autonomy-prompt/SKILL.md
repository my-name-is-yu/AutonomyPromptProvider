---
name: issue-autonomy-prompt
description: Analyze a repository's open GitHub issues, choose the most important issues to tackle next, order them by dependency and leverage, and draft a paste-ready prompt for a separate autonomous development session. Use when the user asks which issues to work on first, wants a top-N issue order, or wants a prompt for a separate autonomous coding session based on GitHub issues.
---

# Issue Autonomy Prompt

Turn a noisy open-issue backlog into a focused autonomous-development prompt.

Use this skill when the user wants:

- the next 3-10 GitHub issues to implement
- the order those issues should be tackled in
- a prompt that can be pasted into another coding session for autonomous implementation
- a nightly or long-running implementation plan based on current open issues

## Core Principle

Treat current repository evidence as authoritative.

Use this priority order:

1. actual issue state from GitHub and local repository state
2. issue bodies and acceptance criteria
3. code and tests that implement or block the requested work
4. recent git/PR history
5. docs and memory

Do not choose issues from memory alone when `gh issue list` and `gh issue view` can cheaply verify the current state.

## Workflow

### 1. Resolve Repository Context

Start from the user's requested workspace if provided. Otherwise use the current working directory.

Run:

```bash
git remote -v
git branch --show-current
gh issue list --state open --limit 100 --json number,title,labels,updatedAt,createdAt,url,assignees
```

If the repo is ambiguous or `gh` is not authenticated, report the blocker and provide the best offline prompt template only if the user can supply issue data.

### 2. Build the Candidate Set

Read issue bodies before ranking final candidates.

Use `gh issue view <number> --json number,title,body,labels,url` for:

- issues explicitly mentioned by the user
- recently created issues related to the user's goal
- likely prerequisites for those issues
- issues that appear to be duplicates, blockers, or already satisfied by recent PRs

Do not read every old issue by default. Use titles, labels, recency, and user intent to narrow the first pass.

### 3. Rank Issues

Prefer issues that unblock long-term autonomous work, observability, safe operation, and concrete user goals.

Rank by these factors, in order:

1. **Prerequisite value**: Does this issue make later issues safer or possible?
2. **Runtime safety**: Does it prevent data loss, unsafe stops, runaway loops, or irreversible actions?
3. **Observability**: Does it make future progress, health, or quality measurable?
4. **Dogfood evidence**: Was the issue seen in a real run, CI failure, or user-observed workflow?
5. **Acceptance clarity**: Can a focused vertical slice satisfy the issue without broad redesign?
6. **Dependency order**: Does another target issue explicitly depend on this one?
7. **User goal fit**: Does it match the user's current stated direction?

Usually avoid selecting:

- duplicate issues unless the duplicate is the canonical issue
- issues that are clearly blocked by unmerged work
- purely cosmetic/documentation issues when runtime/product blockers remain
- broad umbrella issues that should first be split
- issues whose acceptance criteria require external approvals the autonomous session cannot perform

### 4. Produce the Top-N Recommendation

Before drafting the long prompt, summarize the selected issues and why they are ordered that way.

Use this concise shape:

```text
1. #123 <title>
   Why first: <dependency/leverage reason>
2. #124 <title>
   Why second: <reason>
...
```

Mention strong next-tier candidates when useful, but keep the main list focused.

### 5. Draft the Autonomous Development Prompt

The prompt must be paste-ready. It should be specific enough that another session can start work without re-reading this conversation, but it must require that session to verify current repo and issue state before editing.

Include:

- base repository path
- isolated batch worktree path
- startup commands:
  - `git switch <default-branch> && git pull --ff-only`
  - `git fetch origin`
  - `mkdir -p <worktree-root>`
  - conditionally `git worktree add --detach <batch-worktree> origin/<default-branch>`
  - `cd <batch-worktree>`
  - `gh issue list --state open --limit 100`
- target issue list and recommended order
- prerequisites and dependency notes
- implementation rules
- per-issue workflow
- verification commands
- review-agent requirement for substantive changes
- PR and merge policy
- safety/approval constraints
- status-file path
- final-report format

Default status file:

```text
tmp/autonomous-issue-run-status.md
```

If the issue set has a clear theme, choose a more specific path such as:

```text
tmp/nightly-longrun-issues-status.md
tmp/nightly-issues-793-plus-status.md
```

Default worktree strategy:

- Generate prompts that create one isolated worktree for the whole issue batch.
- Use the requested repository as the base repo, and create the worktree outside
  that repo under a sibling or user-specified worktree root.
- Keep the serial execution model: one batch worktree, one active issue branch,
  one PR at a time.
- Do not ask the autonomous session to create one worktree per issue unless the
  user explicitly asks for parallel lanes.
- If the intended worktree path already exists, the generated prompt should tell
  the session to inspect it first and either reuse it only when clean and clearly
  intended for this batch, or choose a new unique path. Do not remove an existing
  dirty worktree as a startup shortcut.
- At the start of each issue, refresh from `origin/<default-branch>`, detach to
  the latest base, and then create that issue's branch.
- When selected issues overlap with active PRs, another parallel batch, or
  user-named dependency PRs, include `gh pr list --state open --limit 50` in the
  startup checks and before each issue starts.

## Prompt Template

Use this template and fill in repository-specific details.

```md
Create a separate worktree from `<BASE_REPO_PATH>`, then implement the
following open issues in order.

Startup steps:
- In the base repository, run
  `git switch <DEFAULT_BRANCH> && git pull --ff-only`.
- Run `git fetch origin`.
- Run `mkdir -p <WORKTREE_ROOT>`.
- If `<BATCH_WORKTREE_PATH>` already exists, inspect it first. Reuse it only
  when it is clean and clearly intended for this batch. If it is dirty or its
  purpose is unclear, do not delete it; choose a new unique worktree path.
- Only when creating a new `<BATCH_WORKTREE_PATH>`, run
  `git worktree add --detach <BATCH_WORKTREE_PATH> origin/<DEFAULT_BRANCH>`.
- Run `cd <BATCH_WORKTREE_PATH>`.
- Re-check current state with `gh issue list --state open --limit 100` and
  `gh issue view <number>` for each target issue.
- If related open PRs or parallel batches exist, also run
  `gh pr list --state open --limit 50`.
- The target issues are currently:
  - #<N1>: <title>
  - #<N2>: <title>
  - #<N3>: <title>
  - #<N4>: <title>
  - #<N5>: <title>
- If a target issue is already closed, skip it and record the reason in the
  status file.
- If related new open issues appear, prioritize completing this target issue
  group. Record only clear blockers, duplicates, or prerequisites in the status
  file.

Core policy:
- Prefer real code, tests, and CLI output over docs or memory.
- Use one issue, one branch, and one PR by default. Do not bundle everything
  into one large PR.
- Work serially inside one batch worktree. Do not implement multiple issues in
  parallel.
- Before each issue, run
  `git fetch origin && git switch --detach origin/<DEFAULT_BRANCH>`, then create
  the issue branch with `git switch -c codex/issue-<number>-<short-name>`.
- If related open PRs or parallel batches exist, run
  `gh pr list --state open --limit 50` before each issue. If a conflict is
  likely, record it in `<STATUS_FILE>` and reorder the issue sequence.
- Respect dependencies. <dependency notes>
- Implement the smallest sufficient vertical slice that satisfies each issue's
  acceptance criteria.
- Do not include unrelated cleanup, broad redesign, or opportunistic fixes.
- For user intent, natural language, runtime state, safety decisions, target
  selection, and workflow semantics, do not ship short-term keyword lists,
  regular expressions, string includes, or title matching as the primary
  decision logic. Prefer typed contracts, schemas, resolvers, state machines,
  model or LLM classifiers, and production caller-path tests that can survive
  input drift.
- Use `rg` and similar searches for investigation, but do not ship decision
  logic based primarily on keyword search.
- Open ready PRs. Do not mark PRs as draft unless the user explicitly asks.
- After substantive changes, get an independent review pass if the environment
  supports it, focused only on material issues.
- Address material findings and re-run validation.
- Merge only if the user explicitly requested merge authority for this run. If
  merge authority was not explicit, stop after ready PR creation and CI/check
  inspection.
- Record decisions, remaining work, and blockers in `<STATUS_FILE>` throughout
  the run.

Recommended implementation order:
1. #<N1>
   - <expected implementation direction>
   - <important acceptance criteria>

2. #<N2>
   - <expected implementation direction>
   - <important acceptance criteria>

3. #<N3>
   - <expected implementation direction>
   - <important acceptance criteria>

4. #<N4>
   - <expected implementation direction>
   - <important acceptance criteria>

5. #<N5>
   - <expected implementation direction>
   - <important acceptance criteria>

Per-issue workflow:
1. `git fetch origin && git switch --detach origin/<DEFAULT_BRANCH>`
2. Read the issue body and acceptance criteria with `gh issue view <number>`.
3. If related open PRs or parallel batches exist, run
   `gh pr list --state open --limit 50`.
4. Trace the relevant code with `rg`. If broad exploration is needed, delegate
   it to an explorer if the environment supports that.
5. Write a short implementation plan to `<STATUS_FILE>`.
6. Create the branch with `git switch -c codex/issue-<number>-<short-name>`.
7. Implement the fix.
8. Add or update tests. Follow the repository's local instructions, and prefer
   production entrypoints and boundary-level contract tests when relevant.
9. Run the repository's standard validation commands. Include relevant focused
   tests. If present and appropriate, run commands such as:
   - `npm run typecheck`
   - `npm test -- <focused-test>`
   - `npm run lint`
   - `npm run test:changed`
10. Get an independent review pass if the environment supports it, focused only
    on material issues.
11. Address material findings and re-run validation.
12. Commit, push, and open a ready PR.
13. The PR body must include:
   - `Closes #<number>`
   - implementation summary
   - validation commands
   - known unresolved risks
   - dependency or integration status for related PRs or parallel batches
14. Inspect CI/checks with `gh pr checks --watch` when available.
15. If merge authority was explicit, CI/checks are green, and review is clear,
    merge with `gh pr merge --squash --delete-branch`.
16. Before moving to the next issue, return to the latest base with
    `git fetch origin && git switch --detach origin/<DEFAULT_BRANCH>`.

Autonomous judgment:
- If CI fails, read the logs and fix the failure. If you conclude it is an
  external flaky failure, record evidence in the status file and PR comment.
- Resolve merge conflicts by fetching `origin/<DEFAULT_BRANCH>` and rebasing or
  merging the current issue branch as appropriate.
- If acceptance criteria are too broad, prefer the smallest useful vertical
  slice and create follow-up issues for the rest. Do not silently ignore
  acceptance criteria.
- If an implementation idea relies on keyword, regex, or string-includes
  classification as the primary decision mechanism, do not use it. First look
  for an existing typed API, schema, state model, model or LLM classifier, or
  domain parser. If none exists, add a durable contract.
- If only a keyword or regex workaround seems possible, record that blocker in
  `<STATUS_FILE>` before implementation and do not ship the workaround.
- Do not perform external publishing, submissions, secret transmission,
  production mutation, irreversible actions, or financial actions. Treat them
  as approval-required.
- If you need to touch issues outside the target set, record the reason in
  `<STATUS_FILE>` before editing.

Final report:
- PRs opened and merged
- issues closed, and issues left open with reasons
- validation commands run
- CI/check results
- follow-up issues
- items needing human judgment
```

## Output Requirements

Return:

1. the ranked issue list
2. the paste-ready autonomous development prompt

If the user asks only for the prompt, still include a short ranking rationale before the prompt unless they explicitly request "prompt only".

## Safety Notes

- Creating a prompt is not approval to perform dangerous actions.
- The generated prompt must explicitly gate external publishing, submissions, secret transmission, production mutation, irreversible actions, and financial actions.
- The generated prompt may allow coding, tests, PR creation, CI inspection, and merge when the user has requested autonomous development and the repository workflow supports it.
