#!/bin/bash
# E2E Test Runner for quicue
#
# Validates the entire quicue vocabulary and patterns work correctly.
# Also tests all linked provider packages.
#
# Usage:
#   ./examples/e2e/run.sh          # Run from quicue root
#   ./examples/e2e/run.sh -v       # Verbose output
#   ./examples/e2e/run.sh -j       # JSON summary only

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUICUE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

VERBOSE=false
JSON_ONLY=false

while getopts "vj" opt; do
    case $opt in
        v) VERBOSE=true ;;
        j) JSON_ONLY=true ;;
    esac
done

cd "$QUICUE_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

if [ "$JSON_ONLY" = true ]; then
    cue export ./examples/e2e/ -e summary
    exit 0
fi

echo "=============================================="
echo "QUICUE E2E TEST SUITE"
echo "=============================================="
echo ""

# Test 1: Validate e2e example
info "Validating e2e example..."
if cue vet -c ./examples/e2e/ 2>/dev/null; then
    pass "e2e validation passed"
else
    fail "e2e validation failed"
    exit 1
fi

# Test 2: Export summary
info "Running test assertions..."
SUMMARY=$(cue export ./examples/e2e/ -e summary 2>/dev/null)

# Check each layer
check_layer() {
    local layer=$1
    local status=$(echo "$SUMMARY" | jq -r ".$layer.status")
    if [ "$status" = "PASS" ]; then
        pass "$layer"
    else
        fail "$layer"
        return 1
    fi
}

check_layer "vocabulary_layer"
check_layer "graph_layer"
check_layer "queries"
check_layer "three_layer_pattern"
check_layer "jsonld_export"

echo ""

# Test 3: Validate all examples
info "Validating all examples..."
EXAMPLES_PASS=true
for ex in graph-patterns multi-region type-composition 3-layer jsonld-export; do
    if [ -d "./examples/$ex" ]; then
        if cue vet "./examples/$ex/" 2>/dev/null; then
            pass "examples/$ex"
        else
            fail "examples/$ex"
            EXAMPLES_PASS=false
        fi
    fi
done

echo ""

# Test 4: Check provider packages (if symlinked)
info "Checking provider packages..."
PROVIDERS="proxmox docker incus k3d vcf"
for provider in $PROVIDERS; do
    PROVIDER_PATH="../quicue-$provider"
    if [ -d "$PROVIDER_PATH" ]; then
        if (cd "$PROVIDER_PATH" && cue vet ./... 2>/dev/null); then
            pass "quicue-$provider"
        else
            fail "quicue-$provider"
        fi
    else
        if [ "$VERBOSE" = true ]; then
            echo "  (skipped: quicue-$provider not found)"
        fi
    fi
done

echo ""
echo "=============================================="

# Final result
OVERALL=$(echo "$SUMMARY" | jq -r '.overall')
if [ "$OVERALL" = "ALL TESTS PASS" ] && [ "$EXAMPLES_PASS" = true ]; then
    echo -e "${GREEN}ALL TESTS PASS${NC}"
    exit 0
else
    echo -e "${RED}SOME TESTS FAILED${NC}"
    exit 1
fi
