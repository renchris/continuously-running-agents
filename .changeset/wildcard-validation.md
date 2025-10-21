---
"continuously-running-agents": patch
---

docs(wildcard): comprehensive validation report and example configuration

Validates and documents the wildcard permissions feature advertised in v2.2.0 CHANGELOG. Identifies critical documentation gap: the promised "Complete reference guide for `.claude/settings.local.json` wildcard patterns" with "145+ organized patterns" does not exist.

**New Files**:
- `WILDCARD-VALIDATION-REPORT.md`: Comprehensive 600+ line validation report
  - Tests 10 diverse wildcard patterns (basic globs, brace expansion, character classes, negation)
  - Documents expected behavior for Read/Write/Bash operations
  - Identifies 8 critical gaps including undocumented pattern precedence rules
  - Provides performance impact analysis and security recommendations
  - Includes production-ready example with 25 patterns

- `.claude/settings.local.json.example`: Production-ready configuration template
  - 60+ well-documented wildcard patterns organized by category
  - Security-focused deny patterns for secrets, dependencies, system directories
  - Extensive inline documentation explaining each pattern
  - Experimental patterns section for untested features

**Key Findings**:
- ⚠️ CHANGELOG claims documentation that doesn't exist (BLOCKER)
- ⚠️ Pattern precedence rules undocumented (CRITICAL)
- ⚠️ Brace expansion, character classes, absolute paths untested
- ⚠️ "95%+ permission prompt reduction" claim unverified
- ⚠️ Security implications of broad patterns undocumented

**Recommendations**:
1. Create comprehensive pattern reference guide (P0)
2. Document pattern precedence and evaluation rules (P0)
3. Run empirical tests with actual Claude Code agent (P1)
4. Benchmark performance impact with various pattern counts (P1)
5. Add security linting for settings.local.json (P2)

Addresses the missing deliverables from v2.2.0 wildcard permissions feature.
