---
"continuously-running-agents": patch
---

docs: documentation cleanup and standardization

**Changes**:
- **GAP-008**: Update README last updated date to October 21, 2025
- **GAP-009**: Standardize all model references to Sonnet 4.5 (current recommended model)
- **GAP-012**: Fix broken script reference in ACTUAL-DEPLOYMENT-COSTS.md

**Impact**:
- All documentation now consistently recommends Sonnet 4.5
- Code examples use correct model IDs (claude-sonnet-4-5)
- Deployment examples reference actual scripts (start-agent-yolo.sh)
- Older models (Sonnet 4, Claude 3.7 Sonnet) marked as superseded

Addresses 3 documentation gaps identified in DOCUMENTATION-GAPS.md analysis. No functional changes - documentation only.
