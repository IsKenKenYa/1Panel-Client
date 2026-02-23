# Fix Log Scroll Error & Optimize MD3 Theme Spec

## Why
- Users reported a crash in the Log Viewer (`The Scrollbar's ScrollController has no ScrollPosition attached`).
- The application lacks proper support for Material Design 3 (Material You) dynamic colors (Monet) on Android 12+.
- The Log Viewer does not correctly adapt to dark/light mode theme changes.

## What Changes
- **Fix Log Viewer**: Explicitly link `ScrollController` to `Scrollbar` and `SingleChildScrollView` in `LogViewer` to prevent "no ScrollPosition" errors.
- **Global Theme Optimization**:
  - Implement `dynamic_color` package for Android 12+ system color support.
  - Create a `ThemeProvider` (or update existing) to manage:
    - Theme Mode (System/Light/Dark).
    - Dynamic Color (On/Off).
    - Custom Seed Color (for non-dynamic or user-override scenarios).
  - Update `MaterialApp` to use the generated `ColorScheme`.
- **Log Viewer UI**:
  - Refactor `LogTheme` to use `ColorScheme` values instead of hardcoded colors where appropriate.
  - Ensure log text and background colors adapt to the current brightness (Light/Dark).

## Impact
- **Affected Specs**: `advanced-log-viewer`.
- **Affected Code**:
  - `lib/shared/widgets/log_viewer/log_viewer.dart`
  - `lib/core/theme/` (New or existing theme logic)
  - `lib/main.dart` (App entry point for theme setup)
  - `lib/shared/widgets/log_viewer/log_theme.dart`

## ADDED Requirements
### Requirement: Dynamic Color Support
The system SHALL support Android 12+ dynamic colors (Monet).
- **WHEN** user enables "Follow System Colors" (default on Android 12+).
- **THEN** the app theme (primary, secondary, background, etc.) SHALL match the system wallpaper palette.

### Requirement: Custom Seed Color
The system SHALL allow users to select a custom seed color.
- **WHEN** dynamic color is disabled or unavailable.
- **THEN** the app theme SHALL be generated from the user-selected seed color using MD3 algorithms.

## MODIFIED Requirements
### Requirement: Log Viewer Stability
- **Fixed**: `Scrollbar` in `LogViewer` (Scroll Page mode) MUST strictly bind to its child's `ScrollController`.

### Requirement: Log Viewer Theming
- **Modified**: Log Viewer default colors MUST be derived from `Theme.of(context).colorScheme` to support Dark/Light mode switching seamlessly.
