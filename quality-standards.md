# Quality Standards

This file documents the quality standards for this knowledge base. These standards ensure the folder itself follows best practices — the meta-quality principle.

## Purpose

- Document what "good" looks like for each part type
- Provide criteria for the audit script
- Enable consistent quality across propagated folders

---

## 1. Folder Organization

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | lowercase-kebab | `daily-prompts.md` |
| Scripts | lowercase-kebab | `propagate-to-all.ps1` |
| Templates | lowercase-kebab | `AGENTS.template.md` |
| Subfolders | lowercase-kebab | `templates/` |

### Structure Rules

- Root-level: core docs, scripts, templates
- Subfolders: domain-specific content
- No orphan files: every file linked from at least one other file
- One source of truth: no duplicate content; files reference, not repeat

### Categorization

```
/ (root)
├── *.md                    # Core documentation
├── *.ps1                   # Scripts and automation
├── templates/              # Reusable templates
├── subfolders/             # Domain-specific content
├── repos.txt              # Config/list files
└── *.json                # State files
```

---

## 2. Script Quality

### Required Elements

Every `.ps1` script must have:

1. **Parameter block** — named parameters, not positional
2. **Help comment** — synopsis, description, examples
3. **Error handling** — try/catch for risky operations
4. **WhatIf support** — `-WhatIf` parameter for dry runs

### Best Practices

- No hardcoded paths: use `$PSScriptRoot` or parameters
- Verbose output: use `-Verbose` for debugging
- Exit codes: 0 for success, 1+ for failure
- Idempotent: safe to run multiple times

### PowerShell Syntax Standards

- Use `param()` block at script start
- Cmdlet naming: `Verb-Noun` (Get-, Set-, New-, Remove-)
- Error handling: `try { } catch { Write-Error; exit 1 }`
- Variables: `$camelCase` or `$PascalCase`
- Strings: double quotes for interpolation, single for literals
- Arrays: `@()` for explicit arrays
- Pipeline: prefer pipeline over loops when appropriate

### Help Comment Template

```powershell
<#
.SYNOPSIS
    Short one-liner description.

.DESCRIPTION
    Longer description of what the script does.

.PARAMETER ParamName
    Description of the parameter.

.EXAMPLE
    .\script.ps1 -ParamName Value
    Example usage with output.

.NOTES
    Author: Name
    Date: YYYY-MM-DD
#>
```

---

## 3. Content Quality

### Tiered Quality Model

| Level | Definition | Requirement |
|-------|------------|--------------|
| **Source-backed** | Links to authoritative external docs | Required for factual claims about tools |
| **Actionable** | Specific steps, commands, paths, examples | Required for "do this" advice |
| **Inference-based** | Derived from patterns, not explicit sources | Must be marked as inference |
| **Generic** | Universal truth (scope tightly, etc) | Fine as-is, common wisdom |

### Content Rules

- **If it's a fact about a tool**: link to official docs
- **If it's advice to act on**: include specific paths, commands, examples
- **If it's uncertain**: mark as "inference" or "likely"
- **Generic principles**: fine as-is (e.g., "scope tightly")

### Link Standards

- External links: must be valid and point to authoritative sources
- Internal links: relative paths preferred
- Placeholders: use `[PLACEHOLDER]` syntax, not `{{PLACEHOLDER}}` or `<PLACEHOLDER>`

### Writing Style

- Concise: avoid unnecessary words
- Specific: include file paths, commands, examples
- Actionable: user can act on the advice
- Scoped: don't ask for "everything" — be specific

---

## 4. Markdown Quality

### Structure

- Heading hierarchy: H1 → H2 → H3, no skipping levels
- Consistent heading style: sentence-case or title-case (pick one)
- Line length: soft-wrap at 100 chars for readability
- Code blocks: fenced with ``` for clarity

### Link Format

```markdown
[Link text](relative/path.md)
[External](https://example.com)
```

### Placeholder Syntax

```
[REPO_NAME]        # Replace this value
[PATH_TO_FILE]    # Path to replace
[COMMAND]         # Command to run
```

---

## 5. Template Quality

### Required Elements

Every template must have:

1. **Header** — description of what the template is for
2. **Placeholders** — clearly marked with `[PLACEHOLDER]`
3. **Usage** — how to use the template
4. **Example** — filled-out example

### Template Naming

- `*.template.md` for markdown templates
- `*.template.ps1` for script templates
- Include `_example.md` with filled values

---

## 6. Meta-Quality

### The Meta Principle

This folder must follow its own advice. Specifically:

- The audit script must pass its own audit
- AGENTS.md must reference these standards
- Propagation flow should include quality checks

### Self-Reference

If these standards describe "good" for a category, the files documenting those standards must exemplify it.

---

## 7. Audit Integration

These standards are enforced by `audit-folder-quality.ps1`.

The checker validates:

- Folder organization (naming, structure, orphans)
- Script quality (parameters, help, error handling)
- Content quality (source-backed links, actionable advice)
- Markdown quality (headings, links, placeholders)
- Template completeness

Run the audit:

```powershell
.\audit-folder-quality.ps1
```

---

## Related Files

- [AGENTS.md](AGENTS.md) — references these standards
- [scripts/audit-folder-quality.ps1](scripts/audit-folder-quality.ps1) — validates these standards
