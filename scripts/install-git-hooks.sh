#!/bin/bash
###############################################################################
# Install Git Hooks for Semantic Commit Enforcement
#
# Sets up:
# - commit-msg hook to validate semantic commit conventions
# - git commit message template with inline examples
#
# Usage:
#   bash scripts/install-git-hooks.sh
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Installing Git Hooks for Commit Validation          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo "Please run this script from the repository root"
    exit 1
fi

# Install commit-msg hook
echo -e "${BLUE}📝 Installing commit-msg hook...${NC}"

if [ ! -f "scripts/commit-msg-hook" ]; then
    echo -e "${RED}❌ Error: scripts/commit-msg-hook not found${NC}"
    exit 1
fi

cp scripts/commit-msg-hook .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg

echo -e "${GREEN}✓ commit-msg hook installed${NC}"
echo ""

# Install commit message template
echo -e "${BLUE}📝 Installing commit message template...${NC}"

if [ ! -f ".gitmessage" ]; then
    echo -e "${YELLOW}⚠️  Warning: .gitmessage not found${NC}"
    echo "Skipping template installation"
else
    git config commit.template .gitmessage
    echo -e "${GREEN}✓ Commit template configured${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Installation Complete!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}What's been set up:${NC}"
echo "  ✓ commit-msg hook (.git/hooks/commit-msg)"
echo "  ✓ Commit template (.gitmessage)"
echo ""
echo -e "${BLUE}What this does:${NC}"
echo "  • Validates commit messages before allowing the commit"
echo "  • Rejects commits with redundant verbs (add, update, fix, etc.)"
echo "  • Enforces lowercase (except proper nouns and acronyms)"
echo "  • Shows helpful error messages when validation fails"
echo ""
echo -e "${BLUE}Test it:${NC}"
echo "  Try: ${YELLOW}git commit -m 'feat: Add new feature'${NC}"
echo "  Result: ${RED}❌ REJECTED${NC} (redundant 'Add', capitalized)"
echo ""
echo "  Try: ${YELLOW}git commit -m 'feat: new feature'${NC}"
echo "  Result: ${GREEN}✅ ACCEPTED${NC}"
echo ""
echo -e "${BLUE}See CONTRIBUTING.md for full conventions${NC}"
echo ""
