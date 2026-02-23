# Tasks

- [x] Task 1: Add Dependencies & Theme Infrastructure
  - [x] SubTask 1.1: Add `dynamic_color` to `pubspec.yaml`.
  - [x] SubTask 1.2: Create `lib/core/theme/theme_controller.dart` (or update existing) to manage `ThemeMode`, `useDynamicColor`, and `seedColor`.
  - [x] SubTask 1.3: Implement persistence for theme settings using `SharedPreferences`.
  - [x] SubTask 1.4: Update `lib/main.dart` to use `DynamicColorBuilder` and consume `ThemeController`.

- [x] Task 2: Fix Log Viewer Scroll Error
  - [x] SubTask 2.1: Modify `lib/shared/widgets/log_viewer/log_viewer.dart` to ensure `Scrollbar` in `LogViewMode.scrollPage` has a valid `ScrollController` attached to its child `SingleChildScrollView`.
  - [x] SubTask 2.2: Verify the fix prevents the "no ScrollPosition" error.

- [x] Task 3: Adapt Log Viewer to MD3 & Dark Mode
  - [x] SubTask 3.1: Refactor `LogTheme` to accept `ColorScheme` and derive default colors from it (e.g., `surface`, `onSurface`, `error`).
  - [x] SubTask 3.2: Update `LogLineWidget` to use these dynamic colors.
  - [x] SubTask 3.3: Verify log viewer appearance in both Light and Dark modes.

- [x] Task 4: Create Theme Settings UI
  - [x] SubTask 4.1: Create a `ThemeSettingsPage` (or add to existing settings) allowing users to:
    - Toggle System/Light/Dark mode.
    - Toggle "Follow System Colors" (Dynamic Color).
    - Select a custom seed color (when Dynamic Color is off).
  - [x] SubTask 4.2: Integrate this page into the app navigation.

# Task Dependencies
- Task 3 depends on Task 1.
- Task 4 depends on Task 1.
