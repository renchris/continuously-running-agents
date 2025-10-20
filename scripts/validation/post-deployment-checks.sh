#!/usr/bin/env bash

################################################################################
# Post-Deployment Health Checks for Continuously Running Agents
#
# This script validates that a newly deployed agent environment is correctly
# configured and operational. It performs comprehensive checks across:
# - Claude API authentication
# - GitHub access and permissions
# - Branch protection configuration
# - System resource availability
# - tmux session management
#
# Usage:
#   ./post-deployment-checks.sh [OPTIONS]
#
# Options:
#   -r, --repo REPO       GitHub repository in format owner/repo (required)
#   -b, --branch BRANCH   Main branch name (default: main)
#   -s, --session NAME    tmux session name to verify (optional)
#   -v, --verbose         Enable verbose output
#   -h, --help           Show this help message
#
# Exit Codes:
#   0 - All checks passed
#   1 - One or more checks failed
#   2 - Invalid arguments or usage
#
# Examples:
#   ./post-deployment-checks.sh --repo myorg/myrepo
#   ./post-deployment-checks.sh -r myorg/myrepo -b main -s agent-session -v
################################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default configuration
REPO=""
BRANCH="main"
TMUX_SESSION=""
VERBOSE=false
CHECKS_PASSED=0
CHECKS_FAILED=0

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
}

print_check() {
    echo -e "${YELLOW}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

print_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "  ${BLUE}ℹ${NC} $1"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

usage() {
    sed -n '2,/^################################################################################$/p' "$0" | sed 's/^# \?//'
    exit 2
}

################################################################################
# Check Functions
################################################################################

check_claude_auth() {
    print_header "Claude API Authentication"

    print_check "Checking for ANTHROPIC_API_KEY environment variable"
    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        print_error "ANTHROPIC_API_KEY not set in environment"
        print_info "Set it with: export ANTHROPIC_API_KEY='your-api-key'"
        return 1
    fi
    print_success "ANTHROPIC_API_KEY is set"

    # Validate API key format
    print_check "Validating API key format"
    if [[ ! "$ANTHROPIC_API_KEY" =~ ^sk-ant-[a-zA-Z0-9_-]+$ ]]; then
        print_error "API key format appears invalid (expected: sk-ant-...)"
        return 1
    fi
    print_success "API key format is valid"

    # Test API connectivity (optional - requires curl and API call)
    print_check "Testing Claude API connectivity"
    local response
    response=$(curl -s -w "\n%{http_code}" -X POST https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d '{
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 10,
            "messages": [{"role": "user", "content": "Hi"}]
        }' 2>/dev/null || echo -e "\n000")

    local http_code
    http_code=$(echo "$response" | tail -n1)

    if [[ "$http_code" == "200" ]]; then
        print_success "Claude API is accessible and responding"
        print_info "API returned HTTP $http_code"
    elif [[ "$http_code" == "401" ]]; then
        print_error "Claude API authentication failed (HTTP 401)"
        print_info "Check if your API key is valid and has not expired"
        return 1
    elif [[ "$http_code" == "000" ]]; then
        print_warning "Could not connect to Claude API (network issue or curl not available)"
        print_info "Skipping API connectivity test"
    else
        print_warning "Claude API returned unexpected status: HTTP $http_code"
        print_info "API may be accessible but check for rate limits or other issues"
    fi
}

check_github_access() {
    print_header "GitHub Access"

    print_check "Checking for gh CLI installation"
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed"
        print_info "Install from: https://cli.github.com/"
        return 1
    fi
    print_success "GitHub CLI is installed"
    print_info "Version: $(gh --version | head -n1)"

    print_check "Checking GitHub authentication status"
    if ! gh auth status &> /dev/null; then
        print_error "Not authenticated with GitHub"
        print_info "Run: gh auth login"
        return 1
    fi
    print_success "Authenticated with GitHub"

    local gh_user
    gh_user=$(gh api user -q .login 2>/dev/null || echo "")
    if [[ -n "$gh_user" ]]; then
        print_info "Logged in as: $gh_user"
    fi

    if [[ -n "$REPO" ]]; then
        print_check "Verifying access to repository: $REPO"
        if ! gh repo view "$REPO" &> /dev/null; then
            print_error "Cannot access repository $REPO"
            print_info "Check repository exists and you have access"
            return 1
        fi
        print_success "Repository $REPO is accessible"

        # Check permissions
        print_check "Checking repository permissions"
        local permissions
        permissions=$(gh api "repos/$REPO" -q .permissions 2>/dev/null || echo "{}")

        local has_push
        has_push=$(echo "$permissions" | grep -o '"push":[^,}]*' | cut -d: -f2 | tr -d ' ')

        if [[ "$has_push" == "true" ]]; then
            print_success "Have push access to repository"
        else
            print_warning "May not have push access to repository"
            print_info "Permissions: $permissions"
        fi
    fi
}

check_branch_protection() {
    print_header "Branch Protection"

    if [[ -z "$REPO" ]]; then
        print_warning "Repository not specified, skipping branch protection checks"
        return 0
    fi

    print_check "Checking branch protection for $BRANCH"
    local protection
    protection=$(gh api "repos/$REPO/branches/$BRANCH/protection" 2>&1 || true)

    if echo "$protection" | grep -q "Not Found"; then
        print_error "No branch protection configured for $BRANCH"
        print_info "Configure protection at: https://github.com/$REPO/settings/branches"
        return 1
    elif echo "$protection" | grep -q "Branch not protected"; then
        print_error "Branch $BRANCH is not protected"
        return 1
    fi

    print_success "Branch protection is enabled for $BRANCH"

    # Check specific protection settings
    print_check "Verifying required status checks"
    local required_checks
    required_checks=$(echo "$protection" | grep -o '"required_status_checks":[^}]*}' || echo "")

    if [[ -n "$required_checks" ]] && [[ "$required_checks" != *"null"* ]]; then
        print_success "Required status checks are configured"
        print_info "Status checks: $required_checks"
    else
        print_warning "No required status checks configured"
    fi

    print_check "Verifying required pull request reviews"
    local pr_reviews
    pr_reviews=$(echo "$protection" | grep -o '"required_pull_request_reviews":[^}]*}' || echo "")

    if [[ -n "$pr_reviews" ]] && [[ "$pr_reviews" != *"null"* ]]; then
        print_success "Pull request reviews are required"
        print_info "Review requirements: $pr_reviews"
    else
        print_warning "Pull request reviews not required"
    fi

    print_check "Checking if admins are subject to restrictions"
    local enforce_admins
    enforce_admins=$(echo "$protection" | grep -o '"enforce_admins":[^,}]*' | cut -d: -f2 | tr -d ' {}')

    if [[ "$enforce_admins" == *"true"* ]]; then
        print_success "Branch protections apply to administrators"
    else
        print_warning "Administrators can bypass branch protections"
        print_info "This may be intentional for automated deployments"
    fi
}

check_resource_usage() {
    print_header "System Resources"

    # CPU usage
    print_check "Checking CPU usage"
    if command -v top &> /dev/null; then
        local cpu_idle
        cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" || echo "0")
        local cpu_usage
        cpu_usage=$(echo "100 - $cpu_idle" | bc 2>/dev/null || echo "unknown")

        if [[ "$cpu_usage" != "unknown" ]]; then
            print_success "CPU usage: ${cpu_usage}%"
            print_info "Idle: ${cpu_idle}%"

            if (( $(echo "$cpu_usage > 80" | bc -l 2>/dev/null || echo 0) )); then
                print_warning "High CPU usage detected"
            fi
        else
            print_info "CPU usage: Unable to determine"
        fi
    else
        print_info "top command not available, skipping CPU check"
    fi

    # Memory usage
    print_check "Checking memory usage"
    if command -v free &> /dev/null; then
        local mem_info
        mem_info=$(free -m | grep Mem:)
        local mem_total
        mem_total=$(echo "$mem_info" | awk '{print $2}')
        local mem_used
        mem_used=$(echo "$mem_info" | awk '{print $3}')
        local mem_percent
        mem_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc)

        print_success "Memory usage: ${mem_used}MB / ${mem_total}MB (${mem_percent}%)"

        if (( $(echo "$mem_percent > 90" | bc -l) )); then
            print_warning "High memory usage detected"
        fi
    else
        print_info "free command not available, skipping memory check"
    fi

    # Disk usage
    print_check "Checking disk usage"
    if command -v df &> /dev/null; then
        local disk_usage
        disk_usage=$(df -h . | tail -n1 | awk '{print $5}' | tr -d '%')
        local disk_info
        disk_info=$(df -h . | tail -n1 | awk '{print $3 " / " $2}')

        print_success "Disk usage: $disk_info ($disk_usage%)"

        if (( disk_usage > 90 )); then
            print_warning "High disk usage detected"
        fi
    else
        print_info "df command not available, skipping disk check"
    fi

    # Load average
    print_check "Checking system load"
    if [[ -f /proc/loadavg ]]; then
        local load_avg
        load_avg=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
        print_success "Load average (1, 5, 15 min): $load_avg"
        print_info "Compare against CPU count: $(nproc 2>/dev/null || echo 'unknown')"
    else
        print_info "/proc/loadavg not available, skipping load check"
    fi
}

check_tmux_sessions() {
    print_header "tmux Sessions"

    print_check "Checking for tmux installation"
    if ! command -v tmux &> /dev/null; then
        print_error "tmux is not installed"
        print_info "Install with: apt-get install tmux (Debian/Ubuntu) or yum install tmux (RHEL/CentOS)"
        return 1
    fi
    print_success "tmux is installed"
    print_info "Version: $(tmux -V)"

    print_check "Listing active tmux sessions"
    local sessions
    sessions=$(tmux list-sessions 2>/dev/null || echo "")

    if [[ -z "$sessions" ]]; then
        print_warning "No active tmux sessions found"
        if [[ -n "$TMUX_SESSION" ]]; then
            print_error "Expected session '$TMUX_SESSION' not found"
            return 1
        fi
    else
        local session_count
        session_count=$(echo "$sessions" | wc -l)
        print_success "Found $session_count active tmux session(s)"
        print_info "Sessions:\n$sessions"

        if [[ -n "$TMUX_SESSION" ]]; then
            print_check "Verifying specific session: $TMUX_SESSION"
            if echo "$sessions" | grep -q "^$TMUX_SESSION:"; then
                print_success "Session '$TMUX_SESSION' is active"

                # Get session details
                local windows
                windows=$(tmux list-windows -t "$TMUX_SESSION" 2>/dev/null || echo "")
                if [[ -n "$windows" ]]; then
                    local window_count
                    window_count=$(echo "$windows" | wc -l)
                    print_info "Session has $window_count window(s)"
                fi
            else
                print_error "Session '$TMUX_SESSION' not found"
                return 1
            fi
        fi
    fi

    # Check for zombie sessions
    print_check "Checking for dead/zombie sessions"
    local zombie_count
    zombie_count=$(tmux list-sessions 2>/dev/null | grep -c "dead" 2>/dev/null || echo "0")
    zombie_count=$(echo "$zombie_count" | head -n1 | tr -d '[:space:]')

    if [[ "$zombie_count" -gt 0 ]] 2>/dev/null; then
        print_warning "Found $zombie_count dead/zombie session(s)"
        print_info "Clean up with: tmux kill-session -t <session-name>"
    else
        print_success "No dead sessions found"
    fi
}

################################################################################
# Main Execution
################################################################################

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repo)
                REPO="$2"
                shift 2
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -s|--session)
                TMUX_SESSION="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
}

main() {
    parse_args "$@"

    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║   Post-Deployment Health Checks                               ║
║   Continuously Running Agents                                 ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    if [[ "$VERBOSE" == true ]]; then
        print_info "Verbose mode enabled"
    fi

    if [[ -n "$REPO" ]]; then
        print_info "Repository: $REPO"
        print_info "Branch: $BRANCH"
    fi

    if [[ -n "$TMUX_SESSION" ]]; then
        print_info "Expected tmux session: $TMUX_SESSION"
    fi

    # Run all checks
    check_claude_auth || true
    check_github_access || true
    check_branch_protection || true
    check_resource_usage || true
    check_tmux_sessions || true

    # Summary
    print_header "Summary"

    local total_checks=$((CHECKS_PASSED + CHECKS_FAILED))
    echo -e "${GREEN}Passed:${NC} $CHECKS_PASSED / $total_checks"
    echo -e "${RED}Failed:${NC} $CHECKS_FAILED / $total_checks"

    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}✓ All critical checks passed!${NC}"
        echo -e "The agent deployment appears healthy and ready for operation.\n"
        return 0
    else
        echo -e "\n${RED}✗ Some checks failed${NC}"
        echo -e "Please review the errors above and fix before proceeding.\n"
        return 1
    fi
}

# Run main function with all arguments
main "$@"
