# Advanced Log Viewer Spec

## Why
The current log viewer is functional but lacks customization and advanced features required by professional users. Specifically, it lacks custom highlighting, internationalization, and advanced navigation tools.

## What Changes

### 1. Extensible Highlighting Engine
- **New Model**: `HighlightRule` (pattern, type [keyword/regex], style [color, bold, etc.]).
- **New Logic**: Refactor `LogLineWidget` to apply a list of `HighlightRule`s dynamically.
- **Default Rules**: Built-in rules for common levels (ERROR, WARN, INFO) and timestamps.

### 2. Visual Color Scheme Editor
- **New UI**: `LogThemeEditor` page.
- **Features**:
    - Add/Edit/Delete rules.
    - Preview changes in real-time.
    - Export/Import rules as JSON.

### 3. Internationalization (i18n)
- **Action**: Extract all hardcoded strings in `LogToolbar`, `LogSettingsSheet`, etc.
- **Files**: Update `app_en.arb` and `app_zh.arb`.

### 4. Enhanced Interaction
- **Jump to Match/Error**: Add "Previous/Next" buttons in the toolbar when searching or when filtering by error.
- **Persisted Settings**: Save font size, wrap, and custom rules to `SharedPreferences` (or Hive).
- **Timestamp Format**: Allow toggling between Absolute (2023-01-01...) and Relative (5 mins ago).

### 5. Performance Optimization
- **Isolates**: Move heavy log parsing (regex matching) to a background isolate using `compute`.

### 6. Accessibility (a11y)
- **Semantic Labels**: Ensure all buttons have `tooltip` and `semanticLabel`.
- **Contrast**: Ensure default themes meet WCAG AA contrast ratios.

## Impact
- **Affected Code**: `lib/shared/widgets/log_viewer/`
- **New Files**: 
    - `lib/shared/widgets/log_viewer/log_theme.dart` (Models)
    - `lib/shared/widgets/log_viewer/log_theme_editor.dart` (UI)
    - `lib/shared/widgets/log_viewer/log_parser.dart` (Isolate logic)

## ADDED Requirements
### Requirement: Custom Highlighting
The system SHALL allow users to define custom regex or keyword rules and assign specific colors and styles (bold, italic) to them.

### Requirement: Theme Persistence
The system SHALL save user-defined highlighting rules and view settings locally so they persist across sessions.

### Requirement: Navigation
The system SHALL provide "Next" and "Previous" buttons to jump between search matches or specific log levels (e.g., jump to next ERROR).

### Requirement: Performance
The system SHALL parse logs in a background thread (Isolate) to prevent UI jank when loading large log files (>10MB).
