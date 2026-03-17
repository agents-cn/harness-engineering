#!/bin/bash
# ─────────────────────────────────────────────────────────
# Harness Engineering Audit Script
# 
# Run from a project root to assess Harness completeness.
# Checks for: documentation, constraints, verification,
# correction signals, and entropy management.
#
# Usage:
#   bash /path/to/harness-engineering/scripts/harness-audit.sh [project_dir]
#   bash /path/to/harness-engineering/scripts/harness-audit.sh --json [project_dir]
# ─────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Parse arguments
JSON_MODE=0
PROJECT_DIR="."
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=1 ;;
        *) PROJECT_DIR="$arg" ;;
    esac
done

cd "$PROJECT_DIR"

# ─────────────────────────────────────────────────────────
# Tech stack auto-detection
# ─────────────────────────────────────────────────────────
IS_JS=0; IS_GO=0; IS_PYTHON=0; IS_RUST=0
[ -f "package.json" ] || [ -f "tsconfig.json" ] && IS_JS=1
[ -f "go.mod" ] && IS_GO=1
[ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] && IS_PYTHON=1
[ -f "Cargo.toml" ] && IS_RUST=1

# Colors (disabled in JSON mode)
if [ "$JSON_MODE" -eq 0 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; NC=''
fi

if [ "$JSON_MODE" -eq 0 ]; then
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║     Harness Engineering Completeness Audit    ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Project: ${CYAN}$(pwd)${NC}"
    echo -e "  Date:    $(date '+%Y-%m-%d %H:%M')"
    DETECTED=""
    [ "$IS_JS" -eq 1 ] && DETECTED="${DETECTED}JS/TS "
    [ "$IS_GO" -eq 1 ] && DETECTED="${DETECTED}Go "
    [ "$IS_PYTHON" -eq 1 ] && DETECTED="${DETECTED}Python "
    [ "$IS_RUST" -eq 1 ] && DETECTED="${DETECTED}Rust "
    [ -z "$DETECTED" ] && DETECTED="Unknown"
    echo -e "  Stack:   ${CYAN}${DETECTED}${NC}"
    echo ""
fi

TOTAL=0
PASSED=0
JSON_RESULTS="[]"

check() {
    local category="$1"
    local id="$2"
    local description="$3"
    local result="$4"  # 0 = pass, 1 = fail
    local fix_hint="$5"

    TOTAL=$((TOTAL + 1))

    if [ "$result" -eq 0 ]; then
        PASSED=$((PASSED + 1))
    fi

    if [ "$JSON_MODE" -eq 1 ]; then
        local status="pass"
        [ "$result" -ne 0 ] && status="fail"
        JSON_RESULTS=$(echo "$JSON_RESULTS" | sed 's/]$//')
        [ "$TOTAL" -gt 1 ] && JSON_RESULTS="${JSON_RESULTS},"
        JSON_RESULTS="${JSON_RESULTS}{\"category\":\"${category}\",\"id\":\"${category}${id}\",\"description\":\"${description}\",\"status\":\"${status}\",\"fix_hint\":\"${fix_hint}\"}]"
    else
        if [ "$result" -eq 0 ]; then
            echo -e "  ${GREEN}✅${NC} ${BOLD}[$category$id]${NC} $description"
        else
            echo -e "  ${RED}❌${NC} ${BOLD}[$category$id]${NC} $description"
            echo -e "     ${YELLOW}→ $fix_hint${NC}"
        fi
    fi
}

# ═══════════════════════════════════════════════
# CONSTRAIN — Mechanical Enforcement
# ═══════════════════════════════════════════════
[ "$JSON_MODE" -eq 0 ] && echo -e "${BOLD}── Constrain (C) ─────────────────────────────${NC}"

# C1: Linter configured
HAS_LINTER=1
if [ "$IS_JS" -eq 1 ]; then
    [ -f ".eslintrc" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.cjs" ] || [ -f ".eslintrc.yml" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || [ -f "biome.json" ] && HAS_LINTER=0
fi
if [ "$IS_GO" -eq 1 ]; then
    [ -f ".golangci.yml" ] || [ -f ".golangci.yaml" ] && HAS_LINTER=0
fi
if [ "$IS_PYTHON" -eq 1 ]; then
    [ -f "ruff.toml" ] || [ -f ".flake8" ] && HAS_LINTER=0
    [ -f "pyproject.toml" ] && grep -q "ruff\|pylint\|flake8" pyproject.toml 2>/dev/null && HAS_LINTER=0
    [ -f "setup.cfg" ] && grep -q "flake8" setup.cfg 2>/dev/null && HAS_LINTER=0
fi
if [ "$IS_RUST" -eq 1 ]; then
    HAS_LINTER=0  # Rust has clippy built-in
fi
check "C" "1" "Linter configured" $HAS_LINTER "Add ESLint/golangci-lint/ruff/clippy config"

# C2: Formatter configured
HAS_FORMATTER=1
if [ "$IS_JS" -eq 1 ]; then
    [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ] || [ -f "biome.json" ] && HAS_FORMATTER=0
fi
if [ "$IS_GO" -eq 1 ]; then
    HAS_FORMATTER=0  # Go uses gofmt by default
fi
if [ "$IS_PYTHON" -eq 1 ]; then
    [ -f "pyproject.toml" ] && grep -q "black\|ruff.*format\|yapf" pyproject.toml 2>/dev/null && HAS_FORMATTER=0
fi
if [ "$IS_RUST" -eq 1 ]; then
    HAS_FORMATTER=0  # Rust uses rustfmt by default
    [ -f "rustfmt.toml" ] || [ -f ".rustfmt.toml" ] && HAS_FORMATTER=0
fi
check "C" "2" "Formatter configured" $HAS_FORMATTER "Add Prettier/gofmt/Black/rustfmt config"

# C3: Pre-commit hooks
HAS_HOOKS=1
[ -f ".simple-git-hooks.cjs" ] || [ -f ".simple-git-hooks.js" ] || [ -f ".lefthook.yml" ] || [ -f ".pre-commit-config.yaml" ] && HAS_HOOKS=0
[ -f "package.json" ] && grep -q "simple-git-hooks" package.json 2>/dev/null && HAS_HOOKS=0
[ -f ".git/hooks/pre-commit" ] && [ -x ".git/hooks/pre-commit" ] && HAS_HOOKS=0
check "C" "3" "Pre-commit hooks installed" $HAS_HOOKS "Add simple-git-hooks/lefthook/pre-commit hooks — see ${SKILL_DIR}/assets/pre-commit-hook.sh"

# C4: Type checking
HAS_TYPES=1
if [ "$IS_JS" -eq 1 ]; then
    [ -f "tsconfig.json" ] && HAS_TYPES=0
fi
if [ "$IS_PYTHON" -eq 1 ]; then
    [ -f "mypy.ini" ] || [ -f ".mypy.ini" ] && HAS_TYPES=0
    [ -f "pyproject.toml" ] && grep -q "mypy\|pyright" pyproject.toml 2>/dev/null && HAS_TYPES=0
fi
if [ "$IS_GO" -eq 1 ]; then
    HAS_TYPES=0  # Go has built-in type checking
fi
if [ "$IS_RUST" -eq 1 ]; then
    HAS_TYPES=0  # Rust has built-in type checking
fi
check "C" "4" "Type checking enabled" $HAS_TYPES "Add tsconfig.json/mypy/pyright config"

# C5: Architecture tests
HAS_ARCH_TESTS=1
if [ "$IS_JS" -eq 1 ]; then
    [ -f ".dependency-cruiser.cjs" ] || [ -f ".dependency-cruiser.js" ] && HAS_ARCH_TESTS=0
fi
find . -maxdepth 4 -name "*.test.*" -exec grep -l "architecture\|dependency.*direction\|layer.*import\|ArchUnit\|archunit" {} + 2>/dev/null | head -1 | grep -q . && HAS_ARCH_TESTS=0
check "C" "5" "Architecture constraint tests" $HAS_ARCH_TESTS "Add dependency-cruiser or architecture unit tests — see ${SKILL_DIR}/assets/arch-test.example.ts"

[ "$JSON_MODE" -eq 0 ] && echo ""

# ═══════════════════════════════════════════════
# INFORM — Structured Context
# ═══════════════════════════════════════════════
[ "$JSON_MODE" -eq 0 ] && echo -e "${BOLD}── Inform (I) ────────────────────────────────${NC}"

# I1: Agent documentation exists
HAS_AGENTS_MD=1
[ -f "AGENTS.md" ] || [ -f "CLAUDE.md" ] || [ -f ".cursorrules" ] || [ -f ".cursor/rules" ] || [ -f ".github/copilot-instructions.md" ] && HAS_AGENTS_MD=0
check "I" "1" "Agent documentation exists (AGENTS.md/CLAUDE.md/.cursorrules)" $HAS_AGENTS_MD "Create AGENTS.md — see ${SKILL_DIR}/assets/AGENTS.md.template"

# I2: Agent doc is concise (not an encyclopedia)
if [ $HAS_AGENTS_MD -eq 0 ]; then
    AGENT_FILE=""
    for f in AGENTS.md CLAUDE.md .cursorrules .github/copilot-instructions.md; do
        [ -f "$f" ] && AGENT_FILE="$f" && break
    done
    if [ -n "$AGENT_FILE" ]; then
        LINE_COUNT=$(wc -l < "$AGENT_FILE" | tr -d ' ')
        if [ "$LINE_COUNT" -le 150 ]; then
            check "I" "2" "Agent doc is concise ($LINE_COUNT lines ≤ 150)" 0 ""
        else
            check "I" "2" "Agent doc is concise ($LINE_COUNT lines > 150)" 1 "Refactor into 100-line directory index + referenced docs"
        fi
    fi
else
    check "I" "2" "Agent doc is concise" 1 "Create AGENTS.md first (I1)"
fi

# I3: Architecture documentation
HAS_ARCH_DOCS=1
[ -f "docs/architecture.md" ] || [ -f "ARCHITECTURE.md" ] || [ -f "docs/arch.md" ] && HAS_ARCH_DOCS=0
find . -maxdepth 2 -name "architecture*" -o -name "ARCHITECTURE*" 2>/dev/null | head -1 | grep -q . && HAS_ARCH_DOCS=0
check "I" "3" "Architecture documentation in repository" $HAS_ARCH_DOCS "Create docs/architecture.md with dependency direction and layer descriptions"

# I4: README with build commands
HAS_README=1
[ -f "README.md" ] && grep -qiE "install|build|test|run|start" README.md 2>/dev/null && HAS_README=0
check "I" "4" "README with build/test/run commands" $HAS_README "Add quick-start commands to README.md"

[ "$JSON_MODE" -eq 0 ] && echo ""

# ═══════════════════════════════════════════════
# VERIFY — Automated Validation
# ═══════════════════════════════════════════════
[ "$JSON_MODE" -eq 0 ] && echo -e "${BOLD}── Verify (V) ────────────────────────────────${NC}"

# V1: Test framework configured
HAS_TESTS=1
if [ "$IS_JS" -eq 1 ]; then
    [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] && HAS_TESTS=0
fi
if [ "$IS_GO" -eq 1 ]; then
    find . -maxdepth 4 -name "*_test.go" 2>/dev/null | head -1 | grep -q . && HAS_TESTS=0
fi
if [ "$IS_PYTHON" -eq 1 ]; then
    [ -f "pytest.ini" ] && HAS_TESTS=0
    [ -f "pyproject.toml" ] && grep -q "pytest\|unittest" pyproject.toml 2>/dev/null && HAS_TESTS=0
fi
if [ "$IS_RUST" -eq 1 ]; then
    [ -f "Cargo.toml" ] && find . -maxdepth 4 -name "*.rs" -exec grep -l "#\[test\]" {} + 2>/dev/null | head -1 | grep -q . && HAS_TESTS=0
fi
check "V" "1" "Test framework configured" $HAS_TESTS "Add Jest/Vitest/pytest/go test/cargo test configuration"

# V2: Tests exist
TEST_COUNT=0
TEST_COUNT=$((TEST_COUNT + $(find . -maxdepth 5 -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.go" -o -name "test_*.py" 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')))
if [ "$TEST_COUNT" -gt 0 ]; then
    check "V" "2" "Test files exist ($TEST_COUNT files found)" 0 ""
else
    check "V" "2" "Test files exist" 1 "Write tests! Start with critical business logic."
fi

# V3: CI pipeline configured
HAS_CI=1
[ -d ".github/workflows" ] && ls .github/workflows/*.yml 2>/dev/null | head -1 | grep -q . && HAS_CI=0
[ -f ".gitlab-ci.yml" ] && HAS_CI=0
[ -f "Jenkinsfile" ] && HAS_CI=0
[ -f ".circleci/config.yml" ] && HAS_CI=0
[ -f "azure-pipelines.yml" ] && HAS_CI=0
check "V" "3" "CI pipeline configured" $HAS_CI "Add .github/workflows/ or .gitlab-ci.yml"

# V4: E2E tests
HAS_E2E=1
[ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ] && HAS_E2E=0
[ -f "cypress.config.ts" ] || [ -f "cypress.config.js" ] && HAS_E2E=0
[ -d "tests/e2e" ] || [ -d "e2e" ] && HAS_E2E=0
check "V" "4" "E2E/integration tests configured" $HAS_E2E "Add Playwright/Cypress or integration test directory"

[ "$JSON_MODE" -eq 0 ] && echo ""

# ═══════════════════════════════════════════════
# CORRECT — Error Recovery
# ═══════════════════════════════════════════════
[ "$JSON_MODE" -eq 0 ] && echo -e "${BOLD}── Correct (R) ───────────────────────────────${NC}"

# R1: Test runner with machine-readable output
HAS_JSON_OUTPUT=1
if [ "$IS_JS" -eq 1 ]; then
    [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] && HAS_JSON_OUTPUT=0
    [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] && HAS_JSON_OUTPUT=0
fi
if [ "$IS_GO" -eq 1 ]; then
    HAS_JSON_OUTPUT=0  # Go supports -json natively
fi
if [ "$IS_RUST" -eq 1 ]; then
    HAS_JSON_OUTPUT=0  # cargo test supports JSON output
fi
check "R" "1" "Test runner supports machine-readable output" $HAS_JSON_OUTPUT "Ensure test runner can output JSON/JUnit XML"

# R2: Error documentation
HAS_ERROR_DOCS=1
find . -maxdepth 3 -name "errors.*" -o -name "error-codes.*" -o -name "known-issues*" 2>/dev/null | grep -v node_modules | head -1 | grep -q . && HAS_ERROR_DOCS=0
check "R" "2" "Error codes/known issues documented" $HAS_ERROR_DOCS "Create docs/known-issues.md or src/errors.ts with structured error codes"

[ "$JSON_MODE" -eq 0 ] && echo ""

# ═══════════════════════════════════════════════
# ENTROPY — Ongoing Health
# ═══════════════════════════════════════════════
[ "$JSON_MODE" -eq 0 ] && echo -e "${BOLD}── Entropy (E) ───────────────────────────────${NC}"

# E1: Git history exists (version control)
HAS_GIT=1
[ -d ".git" ] && HAS_GIT=0
check "E" "1" "Version control (Git)" $HAS_GIT "Initialize git: git init"

# E2: Gitignore configured
HAS_GITIGNORE=1
[ -f ".gitignore" ] && HAS_GITIGNORE=0
check "E" "2" ".gitignore configured" $HAS_GITIGNORE "Add .gitignore for your project type"

# E3: Package lock file (deterministic deps)
HAS_LOCKFILE=1
[ -f "pnpm-lock.yaml" ] || [ -f "package-lock.json" ] || [ -f "yarn.lock" ] || [ -f "go.sum" ] || [ -f "Cargo.lock" ] || [ -f "poetry.lock" ] || [ -f "Pipfile.lock" ] || [ -f "uv.lock" ] && HAS_LOCKFILE=0
check "E" "3" "Dependency lock file exists" $HAS_LOCKFILE "Run package manager install to generate lock file"

[ "$JSON_MODE" -eq 0 ] && echo ""

# ═══════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════
PERCENT=0
if [ $TOTAL -gt 0 ]; then
    PERCENT=$((PASSED * 100 / TOTAL))
fi

RATING=""
if [ $PERCENT -ge 76 ]; then
    RATING="Excellent"
elif [ $PERCENT -ge 51 ]; then
    RATING="Good"
elif [ $PERCENT -ge 26 ]; then
    RATING="Basic"
else
    RATING="Critical"
fi

if [ "$JSON_MODE" -eq 1 ]; then
    DETECTED_STACK=""
    [ "$IS_JS" -eq 1 ] && DETECTED_STACK="${DETECTED_STACK}\"js\","
    [ "$IS_GO" -eq 1 ] && DETECTED_STACK="${DETECTED_STACK}\"go\","
    [ "$IS_PYTHON" -eq 1 ] && DETECTED_STACK="${DETECTED_STACK}\"python\","
    [ "$IS_RUST" -eq 1 ] && DETECTED_STACK="${DETECTED_STACK}\"rust\","
    DETECTED_STACK="[${DETECTED_STACK%,}]"

    cat <<ENDJSON
{
  "project": "$(pwd)",
  "date": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "detected_stack": ${DETECTED_STACK},
  "score": { "passed": $PASSED, "total": $TOTAL, "percent": $PERCENT },
  "rating": "$RATING",
  "checks": $JSON_RESULTS
}
ENDJSON
else
    RATING_COLOR=""
    if [ $PERCENT -ge 76 ]; then
        RATING_COLOR="$BLUE"
    elif [ $PERCENT -ge 51 ]; then
        RATING_COLOR="$GREEN"
    elif [ $PERCENT -ge 26 ]; then
        RATING_COLOR="$YELLOW"
    else
        RATING_COLOR="$RED"
    fi

    echo -e "${BOLD}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Score:${NC}  ${RATING_COLOR}${BOLD}$PASSED / $TOTAL ($PERCENT%)${NC}"
    echo -e "  ${BOLD}Rating:${NC} ${RATING_COLOR}${BOLD}$RATING${NC}"
    echo ""

    if [ $PERCENT -lt 50 ]; then
        echo -e "  ${YELLOW}Recommendation: Start with the ❌ items above.${NC}"
        echo -e "  ${YELLOW}Priority: I1 (AGENTS.md) → C1 (Linter) → C3 (Hooks) → V1 (Tests)${NC}"
    elif [ $PERCENT -lt 76 ]; then
        echo -e "  ${GREEN}Good foundation. Focus on remaining gaps to reach Excellent.${NC}"
    else
        echo -e "  ${BLUE}Strong Harness. Consider entropy management and Agent code review.${NC}"
    fi

    echo ""
    echo -e "  ${CYAN}Full checklist: ${SKILL_DIR}/references/checklist.md${NC}"
    echo ""
fi
