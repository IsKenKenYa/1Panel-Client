# Tasks

- [ ] Task 1: App Store Pagination Refactor
  - [ ] SubTask 1.1: Refactor `AppStoreView` to use `NotificationListener<ScrollNotification>` for pagination.
  - [ ] SubTask 1.2: Ensure `AppStoreProvider` handles pagination state (`page`, `total`, `hasMore`) correctly.

- [ ] Task 2: Implement App Upgrade
  - [ ] SubTask 2.1: Add `upgradeApp` to `AppV2Api` and `AppService` (Endpoint: `/apps/installed/upgrade` or check `installed/op`).
  - [ ] SubTask 2.2: Add `checkUpgrade` to `AppV2Api` and `AppService` (Endpoint: `/apps/installed/update/versions`).
  - [ ] SubTask 2.3: Update `InstalledAppDetailPage` to check for updates on load and show "Upgrade" button if available.
  - [ ] SubTask 2.4: Implement upgrade action in `InstalledAppsProvider`.

- [ ] Task 3: Implement App Config Editing
  - [ ] SubTask 3.1: Add `updateAppConfig` to `AppV2Api` and `AppService` (Endpoint: `/apps/installed/port/change` or `compose/update`? Need to verify API).
  - [ ] SubTask 3.2: Make `ConfigTab` in `InstalledAppDetailPage` editable (TextFields for ports, envs).
  - [ ] SubTask 3.3: Implement save action in `InstalledAppDetailPage` and `InstalledAppsProvider`.

# Task Dependencies
- Task 2 and 3 depend on API verification (SubTasks 2.1, 3.1).
