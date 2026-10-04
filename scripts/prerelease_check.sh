#!/usr/bin/env bash
# Pre-release gate for arunika_app. Spec and severity policy:
# openspec/changes/add-prerelease-security-gate
#
# Usage: scripts/prerelease_check.sh [--allow-missing]
#   --allow-missing    a missing tool is a warning instead of a failure
#
# Not scriptable, record by hand in docs/prerelease-triage.md: a profile-mode
# run on a real device (flutter run --profile + DevTools) for start time and jank.
set -uo pipefail
cd "$(dirname "$0")/.."

REPORT_DIR=prerelease-reports
ALLOW_MISSING=false
for arg in "$@"; do
  case "$arg" in
    --allow-missing) ALLOW_MISSING=true ;;
    *) echo "unknown option: $arg"; sed -n 5,6p "$0"; exit 2 ;;
  esac
done
mkdir -p "$REPORT_DIR"

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'
FAILED=() SKIPPED=()
section() { echo -e "\n${YELLOW}==> $1${NC}"; }
ok()      { echo -e "${GREEN}  ✓ $1${NC}"; }
fail()    { echo -e "${RED}  ✗ $1${NC}"; FAILED+=("$1"); }
skip()    { echo -e "  - skipped: $1"; SKIPPED+=("$1"); }

# need TOOL INSTALL_HINT — succeeds when TOOL is on PATH. A missing tool fails
# the gate unless --allow-missing, so an unscanned repo never looks clean.
need() {
  command -v "$1" >/dev/null 2>&1 && return 0
  if $ALLOW_MISSING; then skip "$1 not installed ($2)"; else fail "$1 not installed — $2"; fi
  return 1
}

# check NAME REPORT CMD... — runs CMD with output to REPORT; pass/fail on exit code.
check() {
  local name="$1" report="$REPORT_DIR/$2"; shift 2
  if "$@" >"$report" 2>&1; then ok "$name"; else fail "$name — see $report"; fi
}

section "Secrets"
if need gitleaks "brew install gitleaks"; then
  check "gitleaks: git history" gitleaks-history.txt \
    gitleaks git --no-banner --redact --report-path "$REPORT_DIR/gitleaks-history.json" .
  # History covers committed files; this covers edits and new files not yet committed.
  changed=$(git ls-files -mo --exclude-standard | grep -v "^$REPORT_DIR/")
  if [ -n "$changed" ]; then
    leaks=0
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      gitleaks dir --no-banner --redact "$f" >>"$REPORT_DIR/gitleaks-worktree.txt" 2>&1 || leaks=1
    done <<<"$changed"
    if [ "$leaks" = 0 ]; then ok "gitleaks: uncommitted changes"
    else fail "gitleaks: uncommitted changes — see $REPORT_DIR/gitleaks-worktree.txt"; fi
  else
    ok "gitleaks: uncommitted changes (none)"
  fi
fi

section "Static analysis"
if need flutter "https://docs.flutter.dev/get-started/install"; then
  check "flutter analyze" flutter-analyze.txt flutter analyze --no-fatal-infos
  # Reviewed by hand: pub.dev has no advisory feed rich enough to gate on.
  flutter pub outdated >"$REPORT_DIR/pub-outdated.txt" 2>&1
  echo "  → review $REPORT_DIR/pub-outdated.txt against pub.dev / GitHub advisories"
fi
check "no TODO/FIXME in auth, payment or entitlement code" todo.txt \
  bash -c "! grep -rnE 'TODO|FIXME' lib | grep -iE '^[^:]*(auth|pay|purchase|billing|entitle|order|token|consent|storage|security)'"

section "Tests"
if command -v flutter >/dev/null 2>&1; then
  check "flutter test --coverage" flutter-test.txt flutter test --coverage
  check "coverage ratchet" coverage-ratchet.txt python3 scripts/coverage_ratchet.py
fi

section "Summary"
echo "Failures: ${#FAILED[@]}   Skipped: ${#SKIPPED[@]}   Reports: $REPORT_DIR/"
for f in ${FAILED[@]+"${FAILED[@]}"}; do echo -e "  ${RED}✗${NC} $f"; done
for s in ${SKIPPED[@]+"${SKIPPED[@]}"}; do echo "  - $s"; done
echo "Triage every finding in docs/prerelease-triage.md before release."
[ "${#FAILED[@]}" -eq 0 ]
