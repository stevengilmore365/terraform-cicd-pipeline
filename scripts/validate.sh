#!/usr/bin/env bash
set -euo pipefail

# Local validation script — runs all checks before pushing
# Usage: ./scripts/validate.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

errors=0

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; errors=$((errors + 1)); }

echo "========================================="
echo "  Terraform CI/CD Pipeline — Validation"
echo "========================================="
echo ""

# 1. Format check
echo "--- Terraform Format ---"
if terraform fmt -check -recursive "$ROOT_DIR/terraform"; then
  log "terraform fmt: all files formatted"
else
  fail "terraform fmt: files need formatting. Run: terraform fmt -recursive terraform/"
fi

# 2. Validate all environments
echo ""
echo "--- Terraform Validate ---"
for env in dev staging prod; do
  dir="$ROOT_DIR/terraform/environments/$env"
  echo "  Validating environment: $env"
  pushd "$dir" > /dev/null
  terraform init -backend=false -input=false > /dev/null 2>&1 || true
  if terraform validate > /dev/null 2>&1; then
    log "  $env: valid"
  else
    fail "  $env: invalid"
    terraform validate
  fi
  popd > /dev/null
done

# 3. TFLint
echo ""
echo "--- TFLint ---"
if command -v tflint &> /dev/null; then
  tflint --init --config "$ROOT_DIR/.tflint.hcl" 2>/dev/null
  if tflint --config "$ROOT_DIR/.tflint.hcl" --recursive "$ROOT_DIR/terraform" 2>&1; then
    log "tflint: no issues"
  else
    warn "tflint: found issues (review above)"
  fi
else
  warn "tflint not installed — skipping"
fi

# 4. tfsec
echo ""
echo "--- tfsec ---"
if command -v tfsec &> /dev/null; then
  if tfsec "$ROOT_DIR/terraform" --format wide 2>&1; then
    log "tfsec: no issues"
  else
    warn "tfsec: found issues (review above)"
  fi
else
  warn "tfsec not installed — skipping"
fi

# 5. Hadolint
echo ""
echo "--- Hadolint ---"
if command -v hadolint &> /dev/null; then
  if hadolint "$ROOT_DIR/Dockerfile"; then
    log "hadolint: no issues"
  else
    fail "hadolint: found issues"
  fi
else
  warn "hadolint not installed — skipping"
fi

# 6. ShellCheck
echo ""
echo "--- ShellCheck ---"
if command -v shellcheck &> /dev/null; then
  if shellcheck "$ROOT_DIR/scripts/"*.sh 2>&1; then
    log "shellcheck: no issues"
  else
    fail "shellcheck: found issues"
  fi
else
  warn "shellcheck not installed — skipping"
fi

# 7. YAML validation
echo ""
echo "--- YAML Validation ---"
if command -v python3 &> /dev/null; then
  python3 -c "
import yaml, glob, sys
errors = []
for f in glob.glob('$ROOT_DIR/.github/workflows/*.yml'):
    try:
        with open(f) as fh:
            yaml.safe_load(fh)
    except Exception as e:
        errors.append(f'{f}: {e}')
if errors:
    for e in errors:
        print(e)
    sys.exit(1)
" && log "YAML: all workflows valid" || fail "YAML: invalid workflows found"
else
  warn "python3 not available — skipping YAML validation"
fi

echo ""
echo "========================================="
if [ "$errors" -gt 0 ]; then
  echo -e "  ${RED}FAILED${NC} — $errors error(s) found"
  exit 1
else
  echo -e "  ${GREEN}PASSED${NC} — all checks clean"
  exit 0
fi
