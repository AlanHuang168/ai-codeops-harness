#!/usr/bin/env bash
#
# Harness Protocol Self-Validation（协议自检）
#
# Minimal contract test. Detects protocol drift introduced by the Risk Router /
# EVAL / Approval / Release Gate changes. It reads only Harness source files and
# runs the installer into a throwaway target; it changes no protocol semantics.
#
# Usage:
#   tests/harness-contract.sh
#
# Exit code: 0 when every contract holds, 1 when any check fails.

set -u
LC_ALL=C
export LC_ALL

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || exit 1
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." 2>/dev/null && pwd -P) || exit 1

PASS=0
FAIL=0
TMP_TARGET=""

cleanup() { [ -n "$TMP_TARGET" ] && [ -d "$TMP_TARGET" ] && rm -rf "$TMP_TARGET"; }
trap cleanup EXIT HUP INT TERM

ok()   { printf 'PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf 'FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

# has FILE LITERAL — fixed-string match anywhere in file
has()  { grep -qF -- "$2" "$ROOT/$1" 2>/dev/null; }
# hasi FILE LITERAL — case-insensitive fixed-string match
hasi() { grep -qiF -- "$2" "$ROOT/$1" 2>/dev/null; }

check() { # DESC ; shift ; command...
  desc=$1
  shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

# all_have "DESC" LITERAL FILE... — literal must appear in every listed file
all_have() {
  desc=$1
  lit=$2
  shift 2
  for f in "$@"; do
    if ! has "$f" "$lit"; then bad "$desc (missing in $f: '$lit')"; return; fi
  done
  ok "$desc"
}

printf '== Harness Protocol Self-Validation ==\n\n'

# ---------------------------------------------------------------------------
# 0. Required files exist
# ---------------------------------------------------------------------------
for f in \
  src/workflows/risk-router.md \
  src/rules/eval.md \
  src/rules/release.md \
  src/workflows/router.md \
  src/workflows/plan.md \
  src/workflows/impl.md \
  src/rules/testing.md \
  adapters/shared/AGENTS.md \
  docs/harness/HARNESS-V2.md \
  docs/harness/RUNTIME-MODEL.md \
  manifest/harness.yaml \
  installer/install.sh
do
  check "exists: $f" test -f "$ROOT/$f"
done

# ---------------------------------------------------------------------------
# 1. Risk tiers Fast / Standard / Architecture defined consistently
# ---------------------------------------------------------------------------
for f in src/workflows/risk-router.md adapters/shared/AGENTS.md; do
  if hasi "$f" "Fast Path" && hasi "$f" "Standard Path" && hasi "$f" "Architecture Path"; then
    ok "tier names present: $f"
  else
    bad "tier names present: $f"
  fi
done
all_have "tier enum 'fast | standard | architecture'" "fast | standard | architecture" \
  src/workflows/plan.md docs/harness/HARNESS-V2.md

# ---------------------------------------------------------------------------
# 2. risk_tier referenced consistently across router / plan / impl / protocol
# ---------------------------------------------------------------------------
all_have "risk_tier field referenced" "risk_tier" \
  src/workflows/risk-router.md src/workflows/plan.md \
  adapters/shared/AGENTS.md docs/harness/HARNESS-V2.md
for f in src/workflows/router.md src/workflows/impl.md; do
  check "Risk Tier concept referenced: $f" hasi "$f" "Risk Tier"
done

# ---------------------------------------------------------------------------
# 3. Terminal states consistent between protocol docs (canonical set)
# ---------------------------------------------------------------------------
CANON_TERMINALS="PLAN_COMPLETE APPROVAL_REQUIRED ARCHITECTURE_DRIFT SCOPE_EXPANSION SECURITY_GATE DESTRUCTIVE_ACTION RELEASE_GATE UNRECOVERABLE_FAILURE"
for state in $CANON_TERMINALS; do
  if has docs/harness/HARNESS-V2.md "$state" && has docs/harness/RUNTIME-MODEL.md "$state"; then
    ok "terminal state in HARNESS-V2 + RUNTIME-MODEL: $state"
  else
    bad "terminal state in HARNESS-V2 + RUNTIME-MODEL: $state"
  fi
done

# ---------------------------------------------------------------------------
# 4. RELEASE_GATE present in protocol AND execution workflow simultaneously
# ---------------------------------------------------------------------------
all_have "RELEASE_GATE in protocol + execution workflow" "RELEASE_GATE" \
  docs/harness/HARNESS-V2.md docs/harness/RUNTIME-MODEL.md \
  src/workflows/impl.md src/rules/release.md src/workflows/risk-router.md

# ---------------------------------------------------------------------------
# 5. Acceptance Contract schema consistent
#    Full schema (technical + business) is authoritative in PLAN (declared) and
#    IMPL (verified). eval.md owns only the Business Half, so it must carry the
#    business side but is not required to duplicate the technical side.
# ---------------------------------------------------------------------------
for f in src/workflows/plan.md src/workflows/impl.md; do
  if has "$f" "acceptance:" && has "$f" "technical:" && has "$f" "business:"; then
    ok "acceptance full schema (technical+business): $f"
  else
    bad "acceptance full schema (technical+business): $f"
  fi
done
if has src/rules/eval.md "acceptance:" && has src/rules/eval.md "business:"; then
  ok "acceptance business half: src/rules/eval.md"
else
  bad "acceptance business half: src/rules/eval.md"
fi

# ---------------------------------------------------------------------------
# 6. EVAL result enum consistent (underscored NOT_RUN, distinct from TEST status)
# ---------------------------------------------------------------------------
for f in src/rules/eval.md src/workflows/impl.md; do
  if has "$f" "PASS" && has "$f" "FAIL" && has "$f" "NOT_RUN" && has "$f" "BLOCKED"; then
    ok "EVAL result enum PASS|FAIL|NOT_RUN|BLOCKED: $f"
  else
    bad "EVAL result enum PASS|FAIL|NOT_RUN|BLOCKED: $f"
  fi
done

# ---------------------------------------------------------------------------
# 7. New src/rules + src/workflows files are covered by installer mappings
# ---------------------------------------------------------------------------
check "manifest maps src/rules"     has manifest/harness.yaml "src/rules"
check "manifest maps src/roles"     has manifest/harness.yaml "src/roles"
check "manifest maps src/workflows" has manifest/harness.yaml "src/workflows"
for f in src/rules/eval.md src/rules/release.md src/workflows/risk-router.md; do
  top=$(printf '%s\n' "$f" | awk -F/ '{print $1"/"$2}')
  case "$top" in
    src/rules|src/roles|src/workflows) ok "installer-mapped location: $f" ;;
    *) bad "installer-mapped location: $f (top=$top)" ;;
  esac
done

# ---------------------------------------------------------------------------
# 8. Architecture Fitness Function contract (ADR -> EVAL -> IMPL loop)
# ---------------------------------------------------------------------------
# 8a. ADR declares the fitness function schema
if has src/workflows/adr.md "fitness_functions:" && has src/workflows/adr.md "constraint:" \
   && has src/workflows/adr.md "measurement:" && has src/workflows/adr.md "result:"; then
  ok "fitness function schema in adr.md"
else
  bad "fitness function schema in adr.md"
fi
# 8b. EVAL rule covers architecture fitness with the same schema
if hasi src/rules/eval.md "Architecture Fitness" && has src/rules/eval.md "fitness_functions:"; then
  ok "architecture fitness covered in eval.md"
else
  bad "architecture fitness covered in eval.md"
fi
# 8c. Execution workflows run fitness functions on the Architecture Path
check "impl.md runs fitness functions" hasi src/workflows/impl.md "fitness function"
check "risk-router.md Verify runs fitness functions" hasi src/workflows/risk-router.md "Fitness Functions"
# 8d. FAIL fitness function is wired to ARCHITECTURE_DRIFT in ADR and IMPL
for f in src/workflows/adr.md src/workflows/impl.md; do
  if hasi "$f" "fitness" && has "$f" "ARCHITECTURE_DRIFT"; then
    ok "fitness FAIL -> ARCHITECTURE_DRIFT: $f"
  else
    bad "fitness FAIL -> ARCHITECTURE_DRIFT: $f"
  fi
done
# 8e. Acceptance Contract carries the optional architecture dimension
for f in src/workflows/plan.md src/workflows/impl.md; do
  check "acceptance architecture dimension: $f" has "$f" "architecture:"
done
# 8f. Fitness functions reuse the EVAL result enum
if has src/workflows/adr.md "PASS" && has src/workflows/adr.md "FAIL" \
   && has src/workflows/adr.md "NOT_RUN" && has src/workflows/adr.md "BLOCKED"; then
  ok "fitness result enum matches EVAL (adr.md)"
else
  bad "fitness result enum matches EVAL (adr.md)"
fi

# ---------------------------------------------------------------------------
# 9. Installer: fresh install + reinstall still pass, new files installed
# ---------------------------------------------------------------------------
TMP_TARGET=$(mktemp -d "${TMPDIR:-/tmp}/harness-contract.XXXXXX") || TMP_TARGET=""
if [ -z "$TMP_TARGET" ]; then
  bad "installer: cannot create temp target"
else
  "$ROOT/installer/install.sh" --target "$TMP_TARGET" --adapter codex claude-code >/dev/null 2>&1
  rc_fresh=$?
  "$ROOT/installer/install.sh" --target "$TMP_TARGET" --adapter codex claude-code >/dev/null 2>&1
  rc_reinstall=$?
  check "installer: fresh install exit 0" test "$rc_fresh" -eq 0
  check "installer: reinstall exit 0"     test "$rc_reinstall" -eq 0
  for f in .ai/workflows/risk-router.md .ai/rules/eval.md .ai/rules/release.md; do
    check "installed: $f" test -f "$TMP_TARGET/$f"
  done
  for p in .ai/workflows/risk-router.md .ai/rules/eval.md .ai/rules/release.md; do
    check "VERSION checksums: $p" grep -qF "$p" "$TMP_TARGET/.ai/VERSION"
  done
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\n== Summary ==\n'
printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
