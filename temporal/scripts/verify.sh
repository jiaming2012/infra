#!/usr/bin/env bash
# =============================================================================
# Temporal Stack — Post-Startup Smoke Test
# =============================================================================
# Run this script after `docker compose up -d` to verify the stack is healthy.
# Usage:  cd infra/temporal && bash scripts/verify.sh
# Make executable with: chmod +x scripts/verify.sh
# =============================================================================

set -euo pipefail

# Run from infra/temporal/ so docker compose picks up the right compose file
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

echo ""
echo "============================================="
echo " Temporal Stack — Smoke Test"
echo "============================================="
echo ""

# ---------------------------------------------------------------------------
# Check 1: All containers are running
# ---------------------------------------------------------------------------
echo "--- Check 1: Container status ---"
COMPOSE_PS=$(docker compose ps --format json 2>/dev/null || docker compose ps 2>/dev/null)
if docker compose ps | grep -qE "(temporal\s|temporal-ui|temporal-admin-tools)"; then
  check_pass "Containers listed in docker compose ps"
else
  check_fail "Containers not found in docker compose ps — is the stack running?"
fi

# ---------------------------------------------------------------------------
# Check 2: Temporal server health via tctl
# ---------------------------------------------------------------------------
echo ""
echo "--- Check 2: Temporal server health ---"
if docker compose exec temporal tctl --address localhost:7233 cluster health 2>/dev/null | grep -qi "pass\|ok\|serving"; then
  check_pass "Temporal cluster health check passed (tctl cluster health)"
else
  check_fail "Temporal cluster health check failed — server may not be ready yet"
fi

# ---------------------------------------------------------------------------
# Check 3: Web UI responds on port 8233
# ---------------------------------------------------------------------------
echo ""
echo "--- Check 3: Web UI HTTP response ---"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8233 2>/dev/null || echo "000")
if [ "${HTTP_CODE}" = "200" ]; then
  check_pass "Web UI returned HTTP 200 at http://localhost:8233"
else
  check_fail "Web UI returned HTTP ${HTTP_CODE} (expected 200) — check temporal-ui container logs"
fi

# ---------------------------------------------------------------------------
# Check 4: Default namespace is accessible
# ---------------------------------------------------------------------------
echo ""
echo "--- Check 4: Namespace access ---"
if docker compose exec temporal temporal operator namespace list 2>/dev/null | grep -q "default\|Namespace"; then
  check_pass "Namespace list returned successfully (at least 'default' namespace visible)"
else
  check_fail "Namespace list failed — Temporal server may not be fully ready"
fi

# ---------------------------------------------------------------------------
# Check 5: gRPC port 7233 is listening
# ---------------------------------------------------------------------------
echo ""
echo "--- Check 5: gRPC port 7233 listening ---"
if curl -s --connect-timeout 3 -o /dev/null http://localhost:7233 2>/dev/null || \
   nc -z localhost 7233 2>/dev/null; then
  check_pass "Port 7233 is open and accepting connections"
else
  check_fail "Port 7233 is not reachable — verify BIND_ON_IP=0.0.0.0 and port mapping"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "============================================="
echo ""

if [ "${FAIL}" -gt 0 ]; then
  echo "Some checks failed. Troubleshooting tips:"
  echo "  - View server logs:    docker compose logs temporal"
  echo "  - View UI logs:        docker compose logs temporal-ui"
  echo "  - Check container ps:  docker compose ps"
  echo ""
  exit 1
fi

echo "All checks passed. Temporal stack is healthy."
echo ""
exit 0
