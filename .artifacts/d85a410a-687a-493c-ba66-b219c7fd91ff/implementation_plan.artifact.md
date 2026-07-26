# Restrict "Rasid" (Balances) Feature by Region

The goal is to hide the "Rasid" (Balances/Income Balances) feature for users located outside of Yemen.

## User Review Required

> [!IMPORTANT]
> I will use the device's system locale (Country Code) to detect if the user is in Yemen. If the device country code is not 'YE', the feature will be hidden.
>
> **Clarification needed**: Do you mean the "الراصد" (Smart Dashboard/Radar) feature or the "الأرصدة" (Income Balances) feature? I will assume you mean the "الأرصدة" (Balances) feature as we were just working on it, but I can apply this to both if needed.

## Proposed Changes

### [Component] Core Services

#### [NEW] [region_service.dart](file:///E:/hemmah/debit_credit_app/lib/core/services/region_service.dart)
- Implement `RegionService` with a getter `isInYemen` using `PlatformDispatcher.instance.locale.countryCode`.

### [Component] UI Navigation

#### [MODIFY] [main_navigation.dart](file:///E:/hemmah/debit_credit_app/lib/core/widgets/main_navigation.dart)
- Conditionally include the "Balances" (الأرصدة) tab in the `_screens` list.
- Conditionally show the "Balances" item in the bottom navigation bar.
- Adjust index handling to ensure navigation remains consistent even when the item is hidden.

#### [MODIFY] [app_drawer.dart](file:///E:/hemmah/debit_credit_app/lib/core/widgets/app_drawer.dart)
- (If applicable) Hide any drawer items related to the restricted feature.

## Verification Plan

### Manual Verification
1.  **Mock Region**: Temporarily hardcode `isInYemen` to `false` and verify the feature is hidden.
2.  **Verify Indices**: Ensure that clicking other tabs still works correctly when one tab is removed.
3.  **Check Persistence**: Ensure that if a user has data in that feature, it's not deleted, just hidden from the UI.
