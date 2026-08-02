# Advanced GitHub Issue Forms Implementation Plan

Upgrade the repository's issue reporting system from basic markdown templates to **GitHub Issue Forms**. This provides a structured, modern UI for users to report bugs and suggest features.

## User Review Required

> [!IMPORTANT]
> **Form Fields**: I have included a dropdown for "Android Version" and "Library Version" to ensure users provide accurate technical data. Let me know if you want to add specific fields for certain Yemeni banks.

## Proposed Changes

### 1. Issue Templates
- **[DELETE] [bug_report.md](file:///E:/Smartfinancialtracker/.github/ISSUE_TEMPLATE/bug_report.md)**: Remove the old markdown template.
- **[NEW] [bug_report.yml](file:///E:/Smartfinancialtracker/.github/ISSUE_TEMPLATE/bug_report.yml)**: A structured form for reporting bugs with:
    - Problem description.
    - Reproduction steps (Step-by-step).
    - Device info (Dropdown for Android 10, 11, 12, 13, 14, 15).
    - Library version.
    - Logcat output field.
- **[DELETE] [feature_request.md](file:///E:/Smartfinancialtracker/.github/ISSUE_TEMPLATE/feature_request.md)**: Remove the old markdown template.
- **[NEW] [feature_request.yml](file:///E:/Smartfinancialtracker/.github/ISSUE_TEMPLATE/feature_request.yml)**: A structured form for new features with:
    - User goal.
    - Proposed solution.
    - Alternatives considered.

### 2. General Config
- **[NEW] [config.yml](file:///E:/Smartfinancialtracker/.github/ISSUE_TEMPLATE/config.yml)**: Add a global configuration for issues, pointing users to Discussions for general questions.

## Verification Plan

### Manual Verification
- Once pushed, go to the **Issues** tab on GitHub and click "New Issue".
- Verify that the new forms appear as a structured UI instead of a simple text box.
- Check that the dropdowns and required fields work as intended.
