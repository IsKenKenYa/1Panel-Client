# Refactor Container Tabs & Fix App Store Issues

## Why
- **Container Management**: The user reports that the Container Management page has incorrect tabs and navigation. Specifically, "Orchestration" is merged into "Container Management", but the app currently navigates to a separate "Orchestration" page. Missing tabs include Overview, Repositories, Templates, and Configuration.
- **App Store**: 
  - Pagination is broken (shows only ~12 apps, API has 230+).
  - "Server Internal Error" on install is not handled gracefully.
  - "Unexpected end of JSON input" error on App Details page.

## What Changes

### Container Management
- **Fix Navigation**: Update `AppRouter` to route `/containers` to `ContainersPage` instead of `OrchestrationPage`.
- **Update Tabs**: Modify `ContainersPage` to include the following 9 tabs in order:
  1.  **Overview** (概览) - New Placeholder/Implementation
  2.  **Containers** (容器) - Existing/Improved
  3.  **Orchestration** (编排) - Embed `ComposePage` here.
  4.  **Images** (镜像) - Existing
  5.  **Networks** (网络) - Existing
  6.  **Volumes** (存储卷) - Existing
  7.  **Repositories** (仓库) - New Placeholder
  8.  **Templates** (编排模版) - New Placeholder
  9.  **Configuration** (配置) - New Placeholder

### App Store
- **Fix JSON Error**: In `AppV2Api`, add checks for empty response bodies before parsing JSON to prevent "unexpected end of JSON input".
- **Fix Pagination**: Verify `AppSearchResponse` parsing logic. Ensure `total` is correctly extracted from the API response so `AppStoreProvider` knows there are more pages.
- **Graceful Error Handling**: Catch 500 errors during install and display a user-friendly `SnackBar` instead of crashing or showing raw exceptions.

## Impact
- **Specs**: `refactor-container-tabs-and-app-store-pagination` (replacing/extending).
- **Code**:
  - `lib/config/app_router.dart`
  - `lib/features/containers/containers_page.dart`
  - `lib/api/v2/app_v2.dart`
  - `lib/features/apps/providers/app_store_provider.dart`

## ADDED Requirements
### Requirement: Container Management Tabs
The Container Management page SHALL display 9 tabs: Overview, Containers, Orchestration, Images, Networks, Volumes, Repositories, Templates, Configuration.
- **Orchestration Tab**: MUST display the content previously in `OrchestrationPage`.

### Requirement: App Store Robustness
- **JSON Parsing**: The system SHALL NOT crash when the API returns an empty body for 200 OK.
- **Pagination**: The system SHALL load the next page of apps when scrolling to the bottom if `total > current_count`.

## MODIFIED Requirements
### Requirement: Navigation
- **Route `/containers`**: MUST navigate to `ContainersPage`.
