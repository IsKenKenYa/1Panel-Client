# Tasks

- [ ] Task 1: Create Log Theme and Highlighting Models
    - [ ] SubTask 1.1: Create `LogHighlightRule` model (pattern, isRegex, color, isBold, isItalic, isUnderline).
    - [ ] SubTask 1.2: Create `LogTheme` class to store a collection of rules.
    - [ ] SubTask 1.3: Update `LogSettings` to include `LogTheme`.

- [ ] Task 2: Implement Background Log Parsing
    - [ ] SubTask 2.1: Extract `parseLogLine` to a standalone function compatible with `compute`.
    - [ ] SubTask 2.2: Implement `LogParser.parse(String logs, LogTheme theme)` using isolate.
    - [ ] SubTask 2.3: Update `LogViewerController` to use `LogParser`.

- [ ] Task 3: Implement Visual Theme Editor
    - [ ] SubTask 3.1: Create `LogThemeEditor` page with rule list.
    - [ ] SubTask 3.2: Create rule editing dialog (color picker, style toggles, regex input).
    - [ ] SubTask 3.3: Implement JSON export/import for themes.

- [ ] Task 4: Refactor LogLineWidget for Dynamic Styles
    - [ ] SubTask 4.1: Update `LogLineWidget` to apply `LogTheme` rules instead of hardcoded colors.
    - [ ] SubTask 4.2: Ensure regex rules are applied efficiently (pre-compile patterns).

- [ ] Task 5: Enhance Navigation and Interaction
    - [ ] SubTask 5.1: Add "Previous/Next" match buttons to `LogToolbar`.
    - [ ] SubTask 5.2: Implement "Jump to Next Error" logic in `LogViewerController`.
    - [ ] SubTask 5.3: Add "Relative Time" toggle.
    - [ ] SubTask 5.4: Persist view settings (font size, wrap, theme) using `SharedPreferences`.

- [ ] Task 6: Internationalization (i18n) and Accessibility
    - [ ] SubTask 6.1: Extract strings from `LogToolbar` and `LogSettingsSheet`.
    - [ ] SubTask 6.2: Add keys to `app_en.arb` and `app_zh.arb`.
    - [ ] SubTask 6.3: Add semantic labels to all icon buttons.

