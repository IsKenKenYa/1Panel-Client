# Log Viewer UI Enhancement Spec

## Why
Currently, the container log viewer (`ContainerLogsView`) displays logs as a single large text block. This has several drawbacks:
- **Performance**: Rendering a huge string is inefficient.
- **Readability**: No syntax highlighting or color coding makes it hard to spot errors or warnings.
- **Usability**: No search functionality, no control over font size or line wrapping, and auto-scroll behavior is basic.

The user explicitly requested "code-like" log display with highlighting and customization options.

## What Changes
- **Refactor `ContainerLogsView`**:
    - Switch from `SingleChildScrollView` + `Text` to `ListView.builder` for efficient rendering of log lines.
    - Implement a split-view or toolbar for log settings.
- **Add `LogSettings`**:
    - Font Size (slider).
    - Line Wrapping (toggle).
    - Theme Selection (Light/Dark/High Contrast).
    - Show/Hide Timestamps (if applicable/parsable).
- **Implement Highlighting**:
    - Use `flutter_highlight` for "code-like" appearance (e.g., using `bash` or `accesslog` mode if available, or a generic theme).
    - Implement custom line-based highlighting for log levels (ERROR=Red, WARN=Yellow, INFO=Green/Blue).
- **Add Search Feature**:
    - Local client-side search within the fetched logs.
    - Highlight matched terms.
    - "Next/Previous" match navigation.
- **Enhance Auto-Scroll**:
    - Add a "Sticky Bottom" toggle that keeps the view at the bottom when new logs arrive (if we implement streaming/polling later, or just for the current fetch).

## Impact
- **Affected Code**: `lib/features/containers/widgets/container_logs_view.dart`
- **New Components**: 
    - `LogToolbar` (Widget)
    - `LogLine` (Widget)
    - `LogSettingsModel` (State)

## ADDED Requirements
### Requirement: High-Performance Log Rendering
The system SHALL use a lazy-loading list (ListView.builder) to render log lines to ensure smooth scrolling even with thousands of lines.

### Requirement: Syntax/Keyword Highlighting
The system SHALL highlight common log keywords:
- `ERROR`, `FATAL`, `EXCEPTION` -> Red
- `WARN`, `WARNING` -> Orange/Yellow
- `INFO`, `DEBUG` -> Blue/Green/Grey
- Dates/Timestamps -> Dimmed color

### Requirement: User Customization
The system SHALL provide a settings panel to allow users to:
- Adjust font size (10pt - 20pt).
- Toggle line wrapping (Wrap / No Wrap).
- Toggle "Dark Mode" for the log area specifically (or follow system).

### Requirement: Search within Logs
The system SHALL provide a search bar to filter or highlight lines containing specific text.

#### Scenario: Search
- **WHEN** user types "error" in search bar
- **THEN** only lines containing "error" are shown OR lines are highlighted and user can jump between matches.

## MODIFIED Requirements
### Requirement: ContainerLogsView
**Modification**: Change internal implementation from `Text` to `ListView`.
