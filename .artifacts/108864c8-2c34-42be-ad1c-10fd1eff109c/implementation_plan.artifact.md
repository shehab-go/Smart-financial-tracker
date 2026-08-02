# GitHub Packages Integration Plan

Enable automated publishing of the library to **GitHub Packages**, allowing developers to include your library in their projects using a standard Maven dependency.

## User Review Required

> [!IMPORTANT]
> **Dependency ID**: The library will be published under:
> `com.github.shehab-go:wallet-events:1.1.0`
> This means other developers will need to authenticate with GitHub to download it, which is standard for GitHub Packages.

## Proposed Changes

### 1. Build Configuration
- **[MODIFY] [financial_tracker/build.gradle.kts](file:///E:/Smartfinancialtracker/financial_tracker/build.gradle.kts)**:
    - Add a `repositories` block inside `publishing`.
    - Configure the GitHub Maven repository with environment variables for credentials.

### 2. Workflow Automation
- **[MODIFY] [.github/workflows/release.yml](file:///E:/Smartfinancialtracker/.github/workflows/release.yml)**:
    - Add `packages: write` permission to the job.
    - Add a step to execute `./gradlew publish` during the release process.
    - Pass `GITHUB_ACTOR` and `GITHUB_TOKEN` to the Gradle environment.

## Verification Plan

### Automated Tests
- Run `./gradlew :financial_tracker:publishReleasePublicationToGitHubPackagesRepository` (locally it might fail without local ENV vars, but the syntax will be checked).

### Manual Verification
- Once a new tag is pushed, verify that the "Packages" section on the GitHub repository home page shows the new package.
