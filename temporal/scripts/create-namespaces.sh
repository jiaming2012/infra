#!/usr/bin/env bash
# =============================================================================
# Temporal Stack — Namespace Creation
# =============================================================================
# Creates project namespaces with 7-day retention. Idempotent — safe to re-run.
# Usage:  cd infra/temporal && bash scripts/create-namespaces.sh
# Make executable with: chmod +x scripts/create-namespaces.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

PASS=0
FAIL=0

check_pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

# Namespaces to create — add new projects here
NAMESPACES=("yumyums" "slack-trading")
RETENTION="7d"

echo ""
echo "============================================="
echo " Temporal Stack — Namespace Creation"
echo "============================================="
echo ""

# ---------------------------------------------------------------------------
# Readiness probe — wait for Temporal to accept namespace operations
# (Pitfall 3: admin-tools container may be running before frontend is ready)
# ---------------------------------------------------------------------------
echo "Waiting for Temporal to be healthy..."
READY=false
for i in $(seq 1 12); do
  if docker compose exec -T temporal-admin-tools \
       temporal operator cluster health > /dev/null 2>&1; then
    READY=true
    echo "Temporal is ready."
    break
  fi
  echo "  Attempt ${i}/12 — retrying in 5s..."
  sleep 5
done

if [ "${READY}" = false ]; then
  echo ""
  check_fail "Temporal did not become healthy within 60 seconds"
  echo "  - Is the stack running? (docker compose up -d)"
  echo "  - Check server logs:  docker compose logs temporal"
  echo ""
  exit 1
fi

echo ""

# ---------------------------------------------------------------------------
# Create namespaces — idempotent via describe-before-create pattern
# ---------------------------------------------------------------------------
for ns in "${NAMESPACES[@]}"; do
  echo "--- Namespace: ${ns} ---"

  # Check if namespace already exists (describe exits 0 if present)
  if docker compose exec -T temporal-admin-tools \
       temporal operator namespace describe --namespace "${ns}" > /dev/null 2>&1; then
    check_pass "Namespace '${ns}' already exists — skipping create"
  else
    # Attempt to create the namespace
    if docker compose exec -T temporal-admin-tools \
         temporal operator namespace create \
         --namespace "${ns}" \
         --retention "${RETENTION}" 2>/dev/null; then
      check_pass "Namespace '${ns}' created (retention=${RETENTION})"
    else
      check_fail "Failed to create namespace '${ns}'"
    fi
  fi
  echo ""
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "============================================="
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "============================================="
echo ""

if [ "${FAIL}" -gt 0 ]; then
  echo "Some namespace operations failed. Troubleshooting:"
  echo "  - View server logs:    docker compose logs temporal"
  echo "  - Check admin-tools:   docker compose logs temporal-admin-tools"
  echo "  - Manual check:        docker compose exec -T temporal-admin-tools temporal operator namespace list"
  echo ""
  exit 1
fi

echo "All namespaces ready."
echo ""
exit 0
