# Tasks

- [x] Task 1: Fix App Navigation & Container Tabs
  - [x] SubTask 1.1: Modify `lib/config/app_router.dart` to route `/containers` to `ContainersPage`.
  - [x] SubTask 1.2: Update `lib/features/containers/containers_page.dart` to implement the 9 required tabs (Overview, Containers, Orchestration, Images, Networks, Volumes, Repositories, Templates, Configuration).
  - [x] SubTask 1.3: Ensure `ComposePage` (Orchestration) is correctly embedded as a tab.

- [x] Task 2: Fix App Store API & Pagination
  - [x] SubTask 2.1: Modify `lib/api/v2/app_v2.dart` to handle empty/null response bodies safely in `getAppDetail` and `installApp`.
  - [x] SubTask 2.2: Verify `AppSearchResponse` parsing in `AppV2Api` to ensure `total` is correctly captured.
  - [x] SubTask 2.3: Update `AppStoreProvider` if necessary to ensure `hasMore` is calculated correctly.

- [x] Task 3: Improve App Store Error Handling
  - [x] SubTask 3.1: Update `AppStoreProvider.installApp` to catch errors and set a user-friendly error message.
  - [x] SubTask 3.2: Update `AppStoreView` to show `SnackBar` on install failure instead of just setting error state (or alongside it).

# Task Dependencies
- Task 1 is independent.
- Task 3 depends on Task 2 (API fixes).
