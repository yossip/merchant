#!/usr/bin/env bash
# ==============================================================================
# Helm Chart Sanity Check — Library Chart Compliance Guardrail
# ==============================================================================
# Validates that application chart templates are thin wrappers that include
# templates from the DevOps-managed library chart (devops-base-chart).
#
# For staging/production environments, ALL configuration must arrive through
# the library chart includes. Direct Kubernetes resource definitions in the
# application chart templates are NOT allowed.
#
# Usage: bash scripts/helm-chart-sanity-check.sh <chart-dir>
# Example: bash scripts/helm-chart-sanity-check.sh ./merchant-core-api-chart
# ==============================================================================

set -euo pipefail

CHART_DIR="${1:?Usage: $0 <chart-dir>}"
TEMPLATES_DIR="${CHART_DIR}/templates"
ERRORS=0

echo "=============================================="
echo " Helm Chart Sanity Check"
echo " Enforcing DevOps library chart compliance"
echo "=============================================="
echo ""
echo "Chart directory: ${CHART_DIR}"
echo ""

# --------------------------------------------------------------------------
# Check 1: Chart.yaml must declare devops-base-chart as a dependency
# --------------------------------------------------------------------------
echo "🔍 Check 1: Verifying library chart dependency..."

if ! grep -q "devops-base-chart" "${CHART_DIR}/Chart.yaml" 2>/dev/null; then
  echo "  ❌ FAIL: Chart.yaml does not declare 'devops-base-chart' as a dependency."
  echo "           All services must inherit from the DevOps-managed library chart."
  ERRORS=$((ERRORS + 1))
else
  echo "  ✅ PASS: devops-base-chart dependency found in Chart.yaml"
fi
echo ""

# --------------------------------------------------------------------------
# Check 2: Library chart must be built (charts/ directory must contain it)
# --------------------------------------------------------------------------
echo "🔍 Check 2: Verifying library chart is packaged..."

if ! ls "${CHART_DIR}/charts/devops-base-chart"*.tgz 1>/dev/null 2>&1; then
  echo "  ❌ FAIL: Library chart package not found in ${CHART_DIR}/charts/"
  echo "           Run 'helm dependency update ${CHART_DIR}' before deploying."
  ERRORS=$((ERRORS + 1))
else
  echo "  ✅ PASS: Library chart package found"
fi
echo ""

# --------------------------------------------------------------------------
# Check 3: Template files (non-helper, non-test) must be thin wrappers
#           that ONLY contain library includes (devops-base.*)
# --------------------------------------------------------------------------
echo "🔍 Check 3: Verifying templates are library includes only..."

TEMPLATE_FILES=$(find "${TEMPLATES_DIR}" -maxdepth 1 -name "*.yaml" -o -name "*.yml" -o -name "*.txt" | sort)

for file in ${TEMPLATE_FILES}; do
  filename=$(basename "${file}")

  # Skip helpers (they're allowed to have wrapper logic)
  if [[ "${filename}" == _* ]]; then
    continue
  fi

  # Strip comments and blank lines, then check if remaining content
  # is ONLY a single include statement calling devops-base.*
  content=$(grep -v '^\s*#' "${file}" | grep -v '^\s*$' || true)

  if [ -z "${content}" ]; then
    echo "  ⚠️  WARN: ${filename} is empty (no rendered content)"
    continue
  fi

  # Check that the content is a single-line devops-base include
  if echo "${content}" | grep -qE '^\{\{-?[[:space:]]*include[[:space:]]+"devops-base\.' && \
     [ "$(echo "${content}" | wc -l)" -le 1 ]; then
    echo "  ✅ PASS: ${filename} → delegates to library chart"
  else
    echo "  ❌ FAIL: ${filename} contains custom resource definitions!"
    echo "           Staging/Production templates must ONLY include from devops-base.*"
    echo "           Found:"
    echo "${content}" | head -5 | sed 's/^/             /'
    ERRORS=$((ERRORS + 1))
  fi
done
echo ""

# --------------------------------------------------------------------------
# Check 4: No raw apiVersion/kind definitions in template files
#           (ensures no one bypasses the library by adding inline resources)
# --------------------------------------------------------------------------
echo "🔍 Check 4: Checking for bypassed inline resource definitions..."

for file in ${TEMPLATE_FILES}; do
  filename=$(basename "${file}")
  [[ "${filename}" == _* ]] && continue

  if grep -q "^apiVersion:" "${file}" 2>/dev/null; then
    echo "  ❌ FAIL: ${filename} contains raw 'apiVersion:' — must use library include"
    ERRORS=$((ERRORS + 1))
  fi
done

# Also check for any new template files in tests/ that bypass the library
TEST_FILES=$(find "${TEMPLATES_DIR}/tests" -name "*.yaml" -o -name "*.yml" 2>/dev/null | sort)
for file in ${TEST_FILES}; do
  filename=$(basename "${file}")
  echo "  ℹ️  INFO: tests/${filename} — test templates are allowed to be self-managed"
done

if [ "${ERRORS}" -eq 0 ]; then
  echo "  ✅ PASS: No inline resource definitions found"
fi
echo ""

# --------------------------------------------------------------------------
# Check 5: Helm lint must pass
# --------------------------------------------------------------------------
echo "🔍 Check 5: Running helm lint..."

if helm lint "${CHART_DIR}" 2>&1 | grep -E "[1-9][0-9]* chart\(s\) failed"; then
  echo "  ❌ FAIL: helm lint reported errors"
  helm lint "${CHART_DIR}" 2>&1 | tail -5
  ERRORS=$((ERRORS + 1))
else
  echo "  ✅ PASS: helm lint passed"
fi
echo ""

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo "=============================================="
if [ "${ERRORS}" -gt 0 ]; then
  echo " ❌ FAILED: ${ERRORS} check(s) failed"
  echo ""
  echo " Staging and Production deployments MUST use the DevOps-managed"
  echo " library chart for all Kubernetes resource definitions."
  echo " Custom templates are only allowed in development."
  echo "=============================================="
  exit 1
else
  echo " ✅ ALL CHECKS PASSED"
  echo ""
  echo " Chart is compliant with DevOps library chart standards."
  echo "=============================================="
  exit 0
fi
