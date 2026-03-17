#!/bin/bash
# Pre-commit hook template for Harness Engineering
# Install: cp <skill-dir>/assets/pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
#   (replace <skill-dir> with the actual path to the harness-engineering skill directory)
# Or use with simple-git-hooks/lefthook for team-wide enforcement.
#
# Principle: Every check here is a mechanical constraint.
# If it's important enough to tell the Agent, it's important enough to enforce here.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Running pre-commit checks..."

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=d)

if [ -z "$STAGED_FILES" ]; then
    echo "No staged files found."
    exit 0
fi

ERRORS=0

# ─────────────────────────────────────────────
# Stage 1: Format Check (fastest)
# ─────────────────────────────────────────────
echo "  → Checking format..."

# Uncomment the formatter for your project:

# TypeScript/JavaScript (Prettier)
# npx prettier --check $(echo "$STAGED_FILES" | grep -E '\.(ts|tsx|js|jsx|json|md)$') 2>/dev/null || ERRORS=$((ERRORS + 1))

# Go
# gofmt -l $(echo "$STAGED_FILES" | grep '\.go$') | grep . && ERRORS=$((ERRORS + 1))

# Python (Black)
# black --check $(echo "$STAGED_FILES" | grep '\.py$') 2>/dev/null || ERRORS=$((ERRORS + 1))

# Rust (rustfmt)
# cargo fmt -- --check 2>/dev/null || ERRORS=$((ERRORS + 1))

# ─────────────────────────────────────────────
# Stage 2: Lint (catches style + custom rules)
# ─────────────────────────────────────────────
echo "  → Running linter..."

# Uncomment for your project:

# TypeScript/JavaScript
# npx eslint $(echo "$STAGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$') 2>/dev/null || ERRORS=$((ERRORS + 1))

# Go
# golangci-lint run $(echo "$STAGED_FILES" | grep '\.go$' | xargs -I{} dirname {} | sort -u) 2>/dev/null || ERRORS=$((ERRORS + 1))

# Python
# ruff check $(echo "$STAGED_FILES" | grep '\.py$') 2>/dev/null || ERRORS=$((ERRORS + 1))

# Rust (clippy)
# cargo clippy -- -D warnings 2>/dev/null || ERRORS=$((ERRORS + 1))

# ─────────────────────────────────────────────
# Stage 3: Type Check (catches type errors)
# ─────────────────────────────────────────────
echo "  → Type checking..."

# Uncomment for your project:

# TypeScript
# npx tsc --noEmit 2>/dev/null || ERRORS=$((ERRORS + 1))

# Python (mypy)
# mypy $(echo "$STAGED_FILES" | grep '\.py$') 2>/dev/null || ERRORS=$((ERRORS + 1))

# ─────────────────────────────────────────────
# Stage 4: Affected Tests (catches logic bugs)
# ─────────────────────────────────────────────
echo "  → Running affected tests..."

# Uncomment for your project:

# Jest (find tests related to changed files)
# npx jest --bail --passWithNoTests --findRelatedTests $(echo "$STAGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$') 2>/dev/null || ERRORS=$((ERRORS + 1))

# Go (test packages with changed files)
# go test $(echo "$STAGED_FILES" | grep '\.go$' | xargs -I{} dirname {} | sort -u | sed 's|^|./|') 2>/dev/null || ERRORS=$((ERRORS + 1))

# Python (pytest)
# pytest $(echo "$STAGED_FILES" | grep '\.py$' | sed 's|\.py$|_test.py|' | xargs -I{} test -f {} && echo {}) 2>/dev/null || ERRORS=$((ERRORS + 1))

# ─────────────────────────────────────────────
# Stage 5: Architecture Constraints (catches structural violations)
# ─────────────────────────────────────────────
echo "  → Checking architecture constraints..."

# Uncomment for your project:

# dependency-cruiser (TypeScript/JavaScript)
# npx dependency-cruiser --validate .dependency-cruiser.cjs src/ 2>/dev/null || ERRORS=$((ERRORS + 1))

# Go (depguard or custom script)
# go vet ./... 2>/dev/null || ERRORS=$((ERRORS + 1))

# ─────────────────────────────────────────────
# Result
# ─────────────────────────────────────────────
if [ $ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Pre-commit failed with $ERRORS error(s).${NC}"
    echo -e "${YELLOW}   Fix the issues above before committing.${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ All pre-commit checks passed.${NC}"
exit 0
