# Tasks

- [x] Task 1: Create Log Settings and State Management
    - [x] SubTask 1.1: Create `LogSettings` model (fontSize, isWrap, theme, showTimestamp).
    - [x] SubTask 1.2: Create `LogViewerController` to manage logs list, search query, and settings.

- [x] Task 2: Refactor `ContainerLogsView` Structure
    - [x] SubTask 2.1: Replace single `Text` widget with `ListView.builder`.
    - [x] SubTask 2.2: Parse the raw log string into a `List<LogLine>` structure (separating timestamp, level, message if possible, or just raw lines).
    - [x] SubTask 2.3: Implement `LogLineWidget` to render a single line with configurable style.

- [x] Task 3: Implement Highlighting
    - [x] SubTask 3.1: Implement regex-based highlighting for log levels (ERROR, WARN, INFO).
    - [x] SubTask 3.2: Integrate `flutter_highlight` or custom TextSpans for coloring.

- [x] Task 4: Implement Search and Toolbar
    - [x] SubTask 4.1: Create `LogToolbar` widget with Search Bar and Settings button.
    - [x] SubTask 4.2: Implement search logic (filter list or jump-to-index).
    - [x] SubTask 4.3: Implement Settings BottomSheet/Dialog to adjust font size and wrap.

- [x] Task 5: Auto-Scroll and UX Polish
    - [x] SubTask 5.1: Implement "Scroll to Bottom" FAB.
    - [x] SubTask 5.2: Ensure sticky scrolling works when refreshing.
