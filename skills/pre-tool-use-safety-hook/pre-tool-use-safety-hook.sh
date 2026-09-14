#!/usr/bin/env bash

# Pre-tool-use safety hook to block destructive bash commands before execution
# Usage: Called by Claude Code before each tool use; scripts should not be called directly except for testing

set -euo pipefail

# Configuration
LOG_PATH="${SAFETY_HOOK_LOG_PATH:-"$HOME/.claude/hooks/blocked.log"}"
ALLOW_LIST="${SAFETY_HOOK_ALLOW_LIST:-}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_PATH")"

# Function to log blocked attempt
log_block() {
    local cmd="$1"
    local project_dir="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "${timestamp} | BLOCKED | ${cmd} | ${project_dir}" >> "$LOG_PATH"
}

# Function to check if command is allowed via allow-list
is_allowed() {
    local cmd="$1"
    if [[ -n "$ALLOW_LIST" ]]; then
        # Simple allow-list: command must contain at least one allowed substring
        for allowed in ${ALLOW_LIST//,/ }; do
            if [[ "$cmd" == *"$allowed"* ]]; then
                return 0
            fi
        done
    fi
    return 1
}

# Function to extract project path (current working directory)
get_project_dir() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Detect destructive patterns (case-insensitive)
block_pattern() {
    local cmd="$1"
    # Lowercase the command for matching
    local lower_cmd="${cmd,,}"

    # Dangerous bash commands
    if [[ "$lower_cmd" == *"rm -rf"* || " $lower_cmd " == *" rm -rf "* || "$lower_cmd" == "rm -rf"* ]]; then
        return 0
    fi

    # Dangerous SQL commands
    if [[ "$lower_cmd" == *"drop table"* || "$lower_cmd" == *"truncate"* ]]; then
        return 0
    fi

    # Dangerous git operations
    if [[ "$lower_cmd" == *"git push --force"* ]];n [[ "$lower_cmd" == *"git push --force"* ]] ]]; then
        return 0
    fi

    # DELETE FROM without WHERE (simple heuristic: presence of "delete from" and no "where")
    if [[ "$lower_cmd" =~ delete[[:space:]]+from[[:space:]]+[a-zA-Z0-9_]+([^[:space:]])*(?!.*where) ]]; then
        return 0
    fi

    # Move or copy to critical system paths
    if [[ "$lower_cmd" =~ (mv|cp)[[:space:]]+.*(/etc/|/usr/|/var/|/bin/|/sbin/) ]]; then
        return 0
    fi

    # Dangerous chmod permissions (777, 000)
    if [[ "$lower_cmd" =~ chmod[[:space:]]+(777|000)[[:space:]] ]]; then
        return 0
    fi

    return 1
}

# Main hook logic
main() {
    # If called directly with arguments, treat as test mode (for manual testing)
    if [[ "$SAFETY_HOOK_TEST" == "1" ]]; then
        # For testing, simulate command line
        if [[ $# -eq 0 ]]; then
            echo "Usage: $0 <command> [args...]"
            exit 1
        fi
        local cmd="$1"
        shift
        local full_cmd="$cmd $@"
        local project_dir="$(get_project_dir)"
        if is_allowed "$full_cmd"; then
            echo "Command allowed via allow-list: $full_cmd"
            exit 0
        fi
        if ! block_pattern "$full_cmd"; then
            echo "Command allowed: $full_cmd"
            exit 0
        fi
        echo "🚫 BLOCKED: Destructive command prevented: $full_cmd"
        echo "Reason: Command contains destructive patterns (rm -rf, DROP TABLE, git push --force, etc.)"
        log_block "$full_cmd" "$project_dir"
        exit 1
    fi

    # Normal Claude Code hook execution: read command from stdin or environment
    # For simplicity, we read the command from $1 (Claude Code passes the full command as first argument)
    if [[ -z "$1" ]]; then
        # No command, nothing to do
        exit 0
    fi

    local full_cmd="$@"
    local project_dir="$(get_project_dir)"

    if is_allowed "$full_cmd"; then
        exit 0
    fi

    if ! block_pattern "$full_cmd"; then
        exit 0
    fi

    echo "🚫 BLOCKED: Destructive command prevented: $full_cmd"
    echo "Reason: Command contains destructive patterns (rm -rf, DROP TABLE, git push --force, DELETE FROM without WHERE, etc.)"
    echo "If you believe this is a false positive, add the command to SAFETY_HOOK_ALLOW_LIST environment variable."
    log_block "$full_cmd" "$project_dir"
    exit 1
}

main "$@"
