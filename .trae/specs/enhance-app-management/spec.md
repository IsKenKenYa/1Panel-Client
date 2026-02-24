# Enhance App Management Spec

## Status
Completed

## Why
The current App Management module lacks critical functionality for installed applications, specifically the ability to upgrade apps and modify their configuration (ports, environment variables, etc.). Additionally, the App Store pagination logic relies on manual scroll position calculation which can be brittle and inconsistent across devices.

## What Changes
- **InstalledAppDetailPage**:
    - [x] Add "Upgrade" button/functionality.
    - [x] Add "Edit Config" functionality (modify ports, environment variables, container name, etc.).
    - [x] Improve "Config" tab to be editable.
    - [x] Add "Detail" view enhancements (e.g. Logs link).
- **AppService / AppV2Api**:
    - [x] Add `upgradeApp` method.
    - [x] Add `updateAppConfig` method (if API exists, or verify usage of `installed/op` or similar).
    - [x] Verify `installed/update/versions` endpoint usage.
- **AppStoreView**:
    - [x] Refactor pagination to use a more robust `NotificationListener<ScrollNotification>` or `InfiniteScrollPagination` approach if applicable, or just clean up the existing logic.

## Impact
- **UI**: `InstalledAppDetailPage`, `AppStoreView`.
- **Providers**: `InstalledAppsProvider`, `AppStoreProvider`.
- **Services**: `AppService`.

## ADDED Requirements

### Requirement: Upgrade Installed App
The system SHALL allow users to upgrade an installed app to a newer version.
- **Scenario**: User views installed app detail -> Checks for updates -> If update available, shows "Upgrade" button -> User clicks -> System upgrades app.

### Requirement: Edit App Config
The system SHALL allow users to edit the configuration of an installed app.
- **Scenario**: User views installed app detail -> Goes to "Config" tab -> Clicks "Edit" -> Modifies ports/envs -> Clicks "Save" -> System updates app config.

### Requirement: App Store Pagination
The system SHALL load more apps smoothly when scrolling to the bottom of the App Store list.
- **Scenario**: User scrolls down -> Loading indicator appears -> More apps are appended.

## MODIFIED Requirements
- **Installed App Detail**: Config tab is now interactive (editable).
