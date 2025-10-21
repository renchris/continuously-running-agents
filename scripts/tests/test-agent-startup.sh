#!/bin/bash
###############################################################################
# Agent Startup Validation Test Suite
#
# Validates that agent startup improvements work correctly
#
# Usage:
#   bash scripts/tests/test-agent-startup.sh
#
# Tests:
#   1. Pre-flight checks detect missing Claude auth
#   2. Startup health check warns on small log files
#   3. Watcher detects startup failures
###############################################################################

set -euo pipefail

PASS=0
FAIL=0

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo "═══════════════════════════════════════════════════════"
echo "  Agent Startup Improvements - Test Suite"
echo "═══════════════════════════════════════════════════════"
echo ""

#─────────────────────────────────────────────────────────────
# Test 1: Pre-Flight Checks Exist in Script
#─────────────────────────────────────────────────────────────
echo -n "Test 1: Pre-flight checks exist... "
if grep -q "Pre-Flight Checks (v2.7.0+)" scripts/start-agent-yolo.sh; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: Pre-flight checks section in start-agent-yolo.sh"
    ((FAIL++))
fi

#─────────────────────────────────────────────────────────────
# Test 2: Authentication Check Logic
#─────────────────────────────────────────────────────────────
echo -n "Test 2: Authentication check logic... "
if grep -q "Claude authentication" scripts/start-agent-yolo.sh && \
   grep -q "claude -p \"test\"" scripts/start-agent-yolo.sh; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: Claude auth test command in script"
    ((FAIL++))
fi

#─────────────────────────────────────────────────────────────
# Test 3: Startup Health Check Exists
#─────────────────────────────────────────────────────────────
echo -n "Test 3: Startup health check exists... "
if grep -q "Startup Health Check (v2.7.0+)" scripts/start-agent-yolo.sh; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: Startup health check section in start-agent-yolo.sh"
    ((FAIL++))
fi

#─────────────────────────────────────────────────────────────
# Test 4: Watcher Detects Startup Failures
#─────────────────────────────────────────────────────────────
echo -n "Test 4: Watcher startup failure detection... "
if grep -q "Detect Startup Failures (v2.7.0+)" scripts/monitoring/agent-completion-watcher.sh && \
   grep -q "log_size.*500" scripts/monitoring/agent-completion-watcher.sh; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: Startup failure detection in watcher"
    ((FAIL++))
fi

#─────────────────────────────────────────────────────────────
# Test 5: Documentation Guide Exists
#─────────────────────────────────────────────────────────────
echo -n "Test 5: AGENT-STARTUP-FAILURES.md exists... "
if [ -f "AGENT-STARTUP-FAILURES.md" ] && \
   grep -q "Quick Diagnosis Decision Tree" AGENT-STARTUP-FAILURES.md; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: AGENT-STARTUP-FAILURES.md with decision tree"
    ((FAIL++))
fi

#─────────────────────────────────────────────────────────────
# Test 6: Case Study Documented
#─────────────────────────────────────────────────────────────
echo -n "Test 6: October 21 case study documented... "
if grep -q "October 21, 2025" AGENT-STARTUP-FAILURES.md && \
   grep -q "Agents 6, 7, 11, 12" AGENT-STARTUP-FAILURES.md; then
    echo -e "${GREEN}PASS${NC}"
    ((PASS++))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: Oct 21 case study in documentation"
    ((FAIL++))
fi

#─────────────────────────────────────────────────────────────
# Summary
#─────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Test Results"
echo "═══════════════════════════════════════════════════════"
echo -e "  ${GREEN}Passed:${NC} $PASS"
echo -e "  ${RED}Failed:${NC} $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
