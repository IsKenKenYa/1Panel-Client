#!/usr/bin/env bash
set -e
# Set repository to use bundled hooks folder and make hook executable

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

git config core.hooksPath .githooks
chmod +x .githooks/commit-msg || true

echo "git hooks configured: core.hooksPath=$(git config --get core.hooksPath)"
echo "commit-msg hook is executable: .githooks/commit-msg"
