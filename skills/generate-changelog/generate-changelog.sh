#!/usr/bin/env bash
set -euo pipefail

# generate-changelog.sh - Generate structured CHANGELOG.md from git history
# Usage: ./generate-changelog.sh [--output FILE] [--limit N] [--since TAG] [--repo PATH]

OUTPUT="CHANGELOG.md"
LIMIT=""
SINCE=""
REPO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output) OUTPUT="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --since) SINCE="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Determine git range
if [[ -n "$SINCE" ]]; then
    RANGE="${SINCE}..HEAD"
elif git describe --tags --abbrev=0 >/dev/null 2>&1; then
    LAST_TAG=$(git describe --tags --abbrev=0)
    RANGE="${LAST_TAG}..HEAD"
else
    RANGE="HEAD"
fi

# Build git log command
GIT_LOG="git log --no-merges --pretty=format:'%h|%s'"
if [[ -n "$LIMIT" ]]; then
    GIT_LOG="$GIT_LOG -n $LIMIT"
fi
GIT_LOG="$GIT_LOG $RANGE"

# Collect commits by type
ADDED=""
FIXED=""
CHANGED=""
REMOVED=""
SECURITY=""
OTHER=""

while IFS='|' read -r hash subject; do
    [[ -z "$hash" ]] && continue

    # Extract type prefix
    if [[ "$subject" =~ ^feat\(!?\): ]]; then
        desc="${subject#feat(!)?: }"
        desc="${subject#feat\(!\): }"
        ADDED="$ADDED\n- $desc ($hash)"
    elif [[ "$subject" =~ ^fix\(!?\): ]]; then
        desc="${subject#fix(!)?: }"
        FIXED="$FIXED\n- $desc ($hash)"
    elif [[ "$subject" =~ ^refactor: ]]; then
        desc="${subject#refactor: }"
        CHANGED="$CHANGED\n- $desc ($hash)"
    elif [[ "$subject" =~ ^perf: ]]; then
        desc="${subject#perf: }"
        CHANGED="$CHANGED\n- $desc ($hash)"
    elif [[ "$subject" =~ ^revert: ]]; then
        desc="${subject#revert: }"
        REMOVED="$REMOVED\n- $desc ($hash)"
    elif [[ "$subject" =~ ^security: ]]; then
        desc="${subject#security: }"
        SECURITY="$SECURITY\n- $desc ($hash)"
    else
        OTHER="$OTHER\n- $subject ($hash)"
    fi
done < <(eval "$GIT_LOG" 2>/dev/null || echo "")

# Write changelog
{
    echo "# Changelog"
    echo ""
    echo "## [Unreleased]"
    echo ""

    if [[ -n "$ADDED" ]]; then
        echo "### Added"
        echo -e "$ADDED"
        echo ""
    fi

    if [[ -n "$FIXED" ]]; then
        echo "### Fixed"
        echo -e "$FIXED"
        echo ""
    fi

    if [[ -n "$CHANGED" ]]; then
        echo "### Changed"
        echo -e "$CHANGED"
        echo ""
    fi

    if [[ -n "$REMOVED" ]]; then
        echo "### Removed"
        echo -e "$REMOVED"
        echo ""
    fi

    if [[ -n "$SECURITY" ]]; then
        echo "### Security"
        echo -e "$SECURITY"
        echo ""
    fi

    if [[ -n "$OTHER" ]]; then
        echo "### Other Changes"
        echo -e "$OTHER"
        echo ""
    fi
} > "$OUTPUT"

echo "Changelog written to $OUTPUT"