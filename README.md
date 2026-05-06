# Issue Autonomy Prompt

A Codex skill for turning an open GitHub issue backlog into a focused,
paste-ready prompt for a separate autonomous coding session.

The skill helps a coding agent:

- inspect live GitHub issue state before choosing work
- rank issues by dependency, risk, and leverage
- create a bounded batch plan
- draft a prompt that starts from a clean worktree
- keep PR creation, validation, and merge authority explicit

## Install

Copy the skill directory into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
rsync -a issue-autonomy-prompt/ ~/.codex/skills/issue-autonomy-prompt/
```

Restart or refresh your Codex session so the skill list is reloaded.

## Usage

Ask Codex to use `issue-autonomy-prompt` when you want a ranked issue plan or a
prompt for another session:

```text
Use issue-autonomy-prompt for this repository. Pick the next five open issues
to tackle, explain the order, and draft a prompt for a separate autonomous
coding session.
```

The generated prompt is designed to verify current repository and issue state
before editing. It also includes a worktree setup path so the implementation
session can work away from the base checkout.

## Safety Defaults

The skill should not treat prompt creation as permission to perform dangerous
actions. Generated prompts should gate external publishing, secret transmission,
production mutation, irreversible actions, financial actions, and merge
authority behind explicit user permission.

By default, generated prompts tell the implementation session to open ready PRs
and inspect checks. They should merge only when the user explicitly granted
merge authority for that run.

## Development

Run the lightweight checker before publishing changes:

```bash
scripts/check-skill.sh
```

Do not tag a release until you have tried the installed skill in a real Codex
session and reviewed the generated prompt shape.
