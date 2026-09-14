#!/usr/bin/env bash
# Test the generate-changelog script

# First, let's create a simple test repo
test_dir="/tmp/changelog_test_repo"
rm -rf "$test_dir"
mkdir -p "$test_dir"
cd "$test_dir"

git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create initial commit
mkdir -p src
echo "Initial code" > src/main.py
git add src/main.py
git commit -m "feat: initial implementation"

# Add more commits
echo "// Added feature" >> src/main.py
git add src/main.py
git commit -m "feat: add new feature"

echo "// Bug fix" >> src/main.py
git add src/main.py
git commit -m "fix: resolve null pointer"

echo "// Refactored" >> src/main.py
git add src/main.py
git commit -m "refactor: improve code structure"

echo "// Security fix" >> src/main.py
git add src/main.py
git commit -m "security: patch SQL injection vulnerability"

echo "// Revert" >> src/main.py
git add src/main.py
git commit -m "revert: undo accidental deletion"

echo "// Perf improvement" >> src/main.py
git add src/main.py
git commit -m "perf: optimize database queries"

echo "// Misc" >> src/main.py
git add src/main.py
git commit -m "docs: update README"

echo "=== Running generate-changelog.sh on test repo ==="
cd /home/ubuntu/.hermes/workspace/claude-builders-bounty
./skills/generate-changelog/generate-changelog.sh --repo "$test_dir" --limit 10 --output /tmp/test_output.md
echo ""
echo "=== Output ==="
cat /tmp/test_output.md