# Changelog Generator Skill

A dependency-free bash script that generates a structured `CHANGELOG.md` from a project's git history, following the Keep a Changelog format.

## Features

- **Auto-categorizes commits** by conventional commit type (feat, fix, refactor, perf, etc.)
- **Tag-aware scoping** — automatically uses the latest git tag as the starting point
- **Keep a Changelog compliant** — produces standard sections (Added, Fixed, Changed, Removed, Security)
- **Zero dependencies** — pure bash, works on any Unix-like system
- **Configurable** — limit commit count, specify custom range, or output to any file

## Quick Start

```bash
# 1. Make the script executable
chmod +x skills/generate-changelog/generate-changelog.sh

# 2. Run from project root
./skills/generate-changelog/generate-changelog.sh

# 3. View the output
cat CHANGELOG.md
```

## Usage Examples

```bash
# Generate changelog for current project
./generate-changelog.sh

# Generate last 50 commits
./generate-changelog.sh --limit 50

# Since a specific tag
./generate-changelog.sh --since v1.2.0

# Output to a custom file
./generate-changelog.sh --output HISTORY.md
```

## Output Format

The generated CHANGELOG.md follows this structure:

```markdown
# Changelog

## [Unreleased]

### Added
- New feature description (abc1234)
- Another feature (def5678)

### Fixed
- Bug fix description (ghi9012)

### Changed
- Refactored module (jkl3456)
```

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
| `security:` | Security |

## Testing

Test on a real repository:

```bash
# Test on this repository itself
cd /path/to/any/git/repo
/path/to/generate-changelog.sh --output /tmp/test-changelog.md
cat /tmp/test-changelog.md
```

## Requirements

- Bash 4.0+
- Git installed and accessible in PATH
- A git repository (initialized with `git init` or cloned)

## License

MIT