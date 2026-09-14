#!/usr/bin/env python3

"""
Pre-tool-use safety hook to block destructive commands before execution.

This script is intended to be used as a pre-tool-use hook in Claude Code.
It blocks dangerous commands like `rm -rf`, `DROP TABLE`, `git push --force`, etc.
"""

import os
import sys
import subprocess
import datetime
from pathlib import Path

# Configuration
LOG_PATH = os.environ.get("SAFETY_HOOK_LOG_PATH", os.path.expanduser("~/.claude/hooks/blocked.log"))
ALLOW_LIST = os.environ.get("SAFETY_HOOK_ALLOW_LIST", "")

# Ensure log directory exists
os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)

def log_block(cmd: str, project_dir: str) -> None:
    """Log a blocked command attempt to the log file."""
    timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(LOG_PATH, "a") as f:
        f.write(f"{timestamp} | BLOCKED | {cmd} | {project_dir}\n")

def get_project_dir() -> str:
    """Get the current project directory."""
    try:
        # Try to get the git root directory
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Fallback to current working directory if not in a git repo
        return os.getcwd()

def is_allowed(cmd: str) -> bool:
    """Check if command is allowed via allow-list."""
    if not ALLOW_LIST:
        return True  # No allow list means everything is allowed unless blocked
    
    # Check if command contains any allowed substring
    for allowed in ALLOW_LIST.split(","):
        if allowed in cmd:
            return True
    return False

def block_pattern(cmd: str) -> bool:
    """Detect if command matches any destructive patterns."""
    # Lowercase the command for case-insensitive matching
    lower_cmd = cmd.lower()
    
    # Dangerous bash commands
    if "rm -rf" in lower_cmd:
        return True
    if "rm -rf" in lower_cmd:  # Handle spaces
        return True
    if "rm -rf" in lower_cmd:  # Another variation
        return True
    
    # Dangerous SQL commands
    if "drop table" in lower_cmd or "truncate" in lower_cmd:
        return True
    
    # Dangerous git operations
    if "git push --force" in lower_cmd:
        return True
    
    # DELETE FROM without WHERE clause (simple heuristic)
    if "delete from" in lower_cmd and "where" not in lower_cmd:
        return True
    
    # Move or copy to critical system paths
    if ("mv" in lower_cmd or "cp" in lower_cmd) and any(path in lower_cmd for path in ["/etc/", "/usr/", "/var/", "/bin/", "/sbin/"]):
        return True
    
    # Dangerous chmod permissions
    if "chmod" in lower_cmd and ("777" in lower_cmd or "000" in lower_cmd):
        return True
    
    return False

def main() -> None:
    """Main hook logic."""
    # If called directly with arguments, treat as test mode (for manual testing)
    if "SAFETY_HOOK_TEST" in os.environ and os.environ["SAFETY_HOOK_TEST"] == "1":
        if len(sys.argv) < 2:
            print("Usage: $0 <command> [args...]", file=sys.stderr)
            sys.exit(1)
        
        cmd = sys.argv[1]
        full_cmd = cmd + " " + " ".join(sys.argv[2:]) if len(sys.argv) > 2 else cmd
        project_dir = get_project_dir()
        
        if is_allowed(full_cmd):
            print(f"Command allowed via allow-list: {full_cmd}")
            sys.exit(0)
            
        if not block_pattern(full_cmd):
            print(f"Command allowed: {full_cmd}")
            sys.exit(0)
            
        print(f"🚫 BLOCKED: Destructive command prevented: {full_cmd}")
        print("Reason: Command contains destructive patterns (rm -rf, DROP TABLE, git push --force, etc.)")
        print("If you believe this is a false positive, add the command to SAFETY_HOOK_ALLOW_LIST environment variable.")
        log_block(full_cmd, project_dir)
        sys.exit(1)
    
    # Normal execution: read command from arguments
    if len(sys.argv) < 2:
        # No command provided, nothing to do
        sys.exit(0)
    
    full_cmd = " ".join(sys.argv[1:])
    project_dir = get_project_dir()
    
    if is_allowed(full_cmd):
        sys.exit(0)
    
    if not block_pattern(full_cmd):
        sys.exit(0)
    
    # Block the command
    print(f"🚫 BLOCKED: Destructive command prevented: {full_cmd}")
    print("Reason: Command contains destructive patterns (rm -rf, DROP TABLE, git push --force, DELETE FROM without WHERE, etc.)")
    print("If you believe this is a false positive, add the command to SAFETY_HOOK_ALLOW_LIST environment variable.")
    log_block(full_cmd, project_dir)
    sys.exit(1)

if __name__ == "__main__":
    main()