# Community Engagement & Future Vision Plan

This plan focuses on the "social" and "future-proofing" aspects of the project, preparing the content for GitHub Wikis, Projects, and a Roadmap.

## User Review Required

> [!TIP]
> **Roadmap Content**: I've included features like "CSV Export" and "AI Classification" in the roadmap. Let me know if you have specific features you'd like to prioritize for future versions.

> [!NOTE]
> **Wiki Strategy**: GitHub Wikis are hosted separately, so I will create the content in a `docs/` folder. This allows you to easily copy-paste it into the GitHub Wiki interface once you make the repo public.

## Proposed Changes

### 1. Vision & Planning
- **[NEW] [ROADMAP.md](file:///E:/Smartfinancialtracker/ROADMAP.md)**: A transparent look at future versions (v1.2, v2.0). Shows potential contributors what's coming next.
- **[NEW] [docs/CONTRIBUTING_GUIDE.md](file:///E:/Smartfinancialtracker/docs/CONTRIBUTING_GUIDE.md)**: A more detailed technical guide for developers on how to set up the project and add new bank parsers.

### 2. Technical Documentation (Wiki Material)
- **[NEW] [docs/architecture.md](file:///E:/Smartfinancialtracker/docs/architecture.md)**: Detailed explanation of the "Event-to-Action" flow:
    - Notification Listener -> Dynamic Parser -> AES Encryption -> Room/SQLite.
- **[NEW] [docs/security-deep-dive.md](file:///E:/Smartfinancialtracker/docs/security-deep-dive.md)**: Explaining the AES-256 implementation and why we hash Reference IDs. This builds trust with users handling financial data.

### 3. Integration
- **[MODIFY] [README.md](file:///E:/Smartfinancialtracker/README.md)**: Add a "Documentation" section linking to the new guides in the `docs/` folder.

## Verification Plan

### Manual Verification
- Verify all links between `README.md`, `ROADMAP.md`, and the `docs/` folder are correct.
- Ensure the technical explanations in `architecture.md` accurately reflect the current code implementation.
- Review the Roadmap for realistic open-source goals.
