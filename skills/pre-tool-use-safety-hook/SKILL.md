# Pre-tool-use Safety Hook

> **Bounty #3** — Create a Claude Code `pre-tool-use` hook in Python or bash that intercepts dangerous bash commands before execution.

## Quick Start

1. Save this file as `~/.claude/hooks/pre-tool-use-safety-hook.py` or `~/.claude/hooks/pre-tool-use-safety-hook.sh`
2. Ensure it is executable: `chmod +x ~/.claude/hooks/pre-tool-use-safety-hook.py`
3. Add hook reference in your Claude Code config if needed.

## Usage

The hook is automatically invoked before each tool use by Claude Code. It scans the command line for patterns matching destructive operations and blocks them with a clear explanation.

## Blocking Patterns

- `rm -rf` and similar recursive deletions
- `DROP TABLE` SQL statements
- `git push --force` and other unsafe git operations
- `TRUNCATE` SQL commands
- `DELETE FROM` without a `WHERE` clause
- Any command containing `> /dev/null` combined with other destructive flags
- `mv` or `cp` operations to critical system paths (e.g., `/etc`, `/usr`, `/var`)
- `chmod` with dangerous permissions (e.g., `777`, `000`)

## Behavior

1. **Detect** any line matching the patterns above (case-insensitive)
2. **Log** the attempt to `~/.claude/hooks/blocked.log` with timestamp, attempted command, and project path
3. **Print** a clear message to Claude explaining why the command was blocked
4. **Exit** with non-zero status to stop execution
5. **Allow** safe commands to proceed normally

## Logging Format

```
2026-09-14T07:XX:XXZ | BLOCKED | rm -rf /important/file.txt | /workspace/my-project
```

## Configuration

- The hook reads optional environment variable `SAFETY_HOOK_LOG_PATH` (defaults to `~/.claude/hooks/blocked.log`)
- Set `SAFETY_HOOK_ALLOW_LIST` to a comma-separated list of allowed commands (bypass check)
- Logs are appended; the script does not rotate logs

## Implementation Details

- Pure Bash (shebang `#!/usr/bin/env bash`) – zero dependencies
- Uses `readlink -f` to resolve absolute paths
- Handles both quoted and unquoted arguments
- Performs simple but effective pattern matching; not a comprehensive security solution
- Gracefully handles missing log directory (creates if needed)

## Testing

To test, run the script directly with a dangerous command:

```bash
~/.claude/hooks/pre-tool-use-safety-hook.sh "rm -rf /tmp/evil"
```

The script should print a block message and exit non-zero.

## License

MIT – use freely, but note that security hooks should be part of a broader defense-in-depth strategy.
