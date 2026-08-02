# Final Mastery: Simulation & Advanced Quality Plan

This plan aims to reach "Absolute Perfection" by adding a transaction simulator for developers and advanced code analysis tools.

## User Review Required

> [!IMPORTANT]
> **Simulator Behavior**: The simulator will generate "Fake" transaction events that look like real bank notifications (STC Pay, mFloos, etc.) to showcase how the library parses and displays them instantly.

## Proposed Changes

### 1. Developer Experience: Mock Simulator
- **[MODIFY] [app/src/main/java/com/shehabgo/sample/ui/DashboardScreen.kt](file:///E:/Smartfinancialtracker/app/src/main/java/com/shehabgo/sample/ui/DashboardScreen.kt)**:
    - Add a Floating Action Button (FAB) with a "Magic Wand" icon.
    - When clicked, it opens a small menu to choose a "Mock Bank" (e.g., STC Pay, Alkuraimi).
- **[NEW] [app/src/main/java/com/shehabgo/sample/simulator/MockTransactionSimulator.kt](file:///E:/Smartfinancialtracker/app/src/main/java/com/shehabgo/sample/simulator/MockTransactionSimulator.kt)**:
    - Logic to trigger `FinancialTrackerClient.testParser()` with hardcoded bank SMS strings and emit them to the UI flow.

### 2. Advanced Code Quality: Detekt
- **[MODIFY] [libs.versions.toml](file:///E:/Smartfinancialtracker/gradle/libs.versions.toml)**: Add `detekt` version and plugin.
- **[MODIFY] [build.gradle.kts](file:///E:/Smartfinancialtracker/build.gradle.kts)**:
    - Apply Detekt plugin to all projects.
    - Configure Detekt to fail on complex code or security smells.
- **[NEW] [config/detekt/detekt.yml](file:///E:/Smartfinancialtracker/config/detekt/detekt.yml)**: Custom rules for the project.

### 3. Gradle Modernization
- **[MODIFY] [libs.versions.toml](file:///E:/Smartfinancialtracker/gradle/libs.versions.toml)**: Add `libraryVersion = "1.1.0"` and `libraryGroup = "com.github.shehab-go"`.
- **[MODIFY] [financial_tracker/build.gradle.kts](file:///E:/Smartfinancialtracker/financial_tracker/build.gradle.kts)**: Use the centralized versioning from TOML.

## Verification Plan

### Automated Tests
- Run `./gradlew detekt` to find logic flaws.
- Run `./gradlew build` to ensure the new simulator code compiles correctly.

### Manual Verification
- Open the Sample App, click the FAB, and verify that selecting a bank adds a "Success" transaction to the list instantly.
