---
name: generate-changelog
description: Generate a structured CHANGELOG.md from a project's git history. Use when asked to create a changelog, summarize releases, or document version history.
category: tooling
---

# Generate Changelog

Generate a structured CHANGELOG.md from a project's git history using conventional commit types.

## Quick Start

```bash
./generate-changelog.sh
```

## Usage

```bash
# Generate for current directory
./generate-changelog.sh

# Output to custom file
./generate-changelog.sh --output CHANGELOG.md

# Limit commit count
./generate-changelog.sh --limit 50

# Since specific tag
./generate-changelog.sh --since v1.0.0
```

## Output Format

The script produces a Keep a Changelog compliant Markdown file with sections:

- **Added** — new features
- **Fixed** — bug fixes
- **Changed** — modifications to existing functionality
- **Removed** — deprecated features
- **Security** — security vulnerability fixes

## Commit Type Mapping

| Prefix | Section |
|--------|---------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:` | Changed |
| `perf:` | Changed |
| `docs:` | Documentation |
| `chore:` | Maintenance |
| `test:` | Tests |
| `style:` | Styling |
| `ci:` | CI/CD |
| `build:` | Build system |
| `revert:` | Reverted |