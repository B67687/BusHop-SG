<!-- Managed-By: AI-Prompting-Library -->
<!-- Template: AGENTS -->
# Repo Instructions

Use this file before making code, CI, issue, or PR changes in this repository.

## Core Workflow

1. Build context before editing.
2. Prefer root-cause fixes over symptom patches.
3. Use the smallest maintainable change.
4. Verify with the closest local equivalent of CI or production behavior.
5. Summarize root cause, fix, verification, and residual risk.

## Required Checks

- Setup: [install command]
- Test: [test command]
- Lint: [lint command]
- Build: [build command]

## Reasoning Effort

- Default to `medium` for normal repo work.
- Use `low` for obvious, local, easy-to-verify changes.
- Use `high` for ambiguous debugging, cross-file changes, or riskier work.
- Use `xhigh` for broad, difficult, or expensive-to-get-wrong tasks.
- Increase effort when ambiguity, scope, unfamiliarity, or regression risk goes up.

## Repo Conventions

- [branching rule]
- [PR title/body rule]
- [issue rule]
- [style or architecture rule]

## Scope Boundaries

- keep team-shared repo rules here
- keep personal preferences or secrets out of committed files
- keep subsystem-specific rules close to the subsystem when needed

## Do-Not Rules

- never bypass tests
- never hide residual risk
- never skip platform or architecture checks that matter here

## Local Lessons

Before PR or issue work, read:
- [LESSONS_FILE_NAME]

If a maintainer reveals a new convention, update that file before continuing similar work.
If a lesson should change how work is done in other repos too, record it cleanly so it can be promoted later into the central library.

## Quality Standards

This workspace follows its own quality standards. See [quality-standards.md](../quality-standards.md) for the criteria.

Run the audit:
```powershell
.\scripts\audit-folder-quality.ps1
```

The audit validates:
- Folder organization (naming, structure)
- Script quality (parameters, help, error handling)
- Content quality (source-backed claims, actionable advice)
- Markdown quality (headings, links, placeholders)
- Template completeness

