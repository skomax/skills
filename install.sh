#!/bin/bash
# Claude Code Skills & Rules Installer
# Usage: ./install.sh [target_project_path]
#
# Copies .claude/ folder and CLAUDE.md to the target project.
# If no path given, copies to current directory.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"

# Resolve absolute path
TARGET="$(cd "$TARGET" && pwd)"

echo "Installing Claude Code Skills & Rules..."
echo "Source: $SCRIPT_DIR"
echo "Target: $TARGET"
echo ""

# Check if .claude already exists
if [ -d "$TARGET/.claude" ]; then
    echo "WARNING: $TARGET/.claude/ already exists."
    read -p "Merge (existing files will be preserved)? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Copy .claude directory (merge, don't overwrite existing)
echo "Copying rules..."
mkdir -p "$TARGET/.claude/rules"
cp -n "$SCRIPT_DIR/.claude/rules/"*.md "$TARGET/.claude/rules/" 2>/dev/null || true

echo "Copying skills..."
for skill_dir in "$SCRIPT_DIR/.claude/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$TARGET/.claude/skills/$skill_name"
    cp -n "$skill_dir"* "$TARGET/.claude/skills/$skill_name/" 2>/dev/null || true
done

echo "Copying commands..."
for cmd_dir in "$SCRIPT_DIR/.claude/commands"/*/; do
    cmd_name=$(basename "$cmd_dir")
    mkdir -p "$TARGET/.claude/commands/$cmd_name"
    cp -n "$cmd_dir"* "$TARGET/.claude/commands/$cmd_name/" 2>/dev/null || true
done

# Copy CLAUDE.md only if it doesn't exist
if [ ! -f "$TARGET/CLAUDE.md" ]; then
    echo "Copying CLAUDE.md..."
    cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
else
    echo "CLAUDE.md already exists, skipping (check CLAUDE.md.template for reference)."
    cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md.template"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Structure installed:"
echo "  .claude/rules/     - 6 rule files (auto-loaded by file patterns)"
echo "  .claude/skills/    - 15 skill directories (activated by context)"
echo "  .claude/commands/  - 10 slash commands (/dev:*, /test:*, /project:*, /deploy:*)"
echo "  CLAUDE.md          - Master configuration"
echo ""
echo "Available commands:"
echo "  /dev:code-review       - Comprehensive code review"
echo "  /dev:plan              - Implementation planning"
echo "  /dev:tdd               - Test-driven development workflow"
echo "  /dev:debug             - Systematic debugging"
echo "  /dev:refactor          - Safe refactoring with tests"
echo "  /test:run              - Run tests with coverage"
echo "  /project:init          - Initialize new project"
echo "  /project:status        - Project health check"
echo "  /deploy:docker-rebuild - Rebuild and test Docker containers"
echo "  /deploy:prod           - Production deployment checklist"
