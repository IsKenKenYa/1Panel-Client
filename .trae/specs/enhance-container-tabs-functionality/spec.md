# Enhance Container Tabs Functionality Spec

## Why
The Container Management page has been restructured to include 9 tabs, but several tabs (Orchestration, Networks, Volumes, Repositories, Templates, Config) lack full functionality (Create, Edit, Delete) or are read-only placeholders. The user requires these tabs to be fully functional based on the available API endpoints.

## What Changes
- **ContainersPage**:
  - Update `FloatingActionButton` logic to support "Create" actions for multiple tabs (Compose, Network, Volume, Repo, Template).
- **ComposePage**:
  - Add "Create Project" functionality.
- **NetworkPage**:
  - Add "Create Network" functionality.
- **VolumePage**:
  - Add "Create Volume" functionality.
- **ReposTab**:
  - Add "Create Repository" functionality.
  - Add "Delete" and "Edit" actions to list items.
- **TemplatesTab**:
  - Add "Create Template" functionality.
  - Add "Delete" and "Edit" actions to list items.
- **ConfigTab**:
  - Add "Edit" mode to modify and save `daemon.json`.

## Impact
- **UI**: `ContainersPage` and its sub-tabs.
- **Providers**: `ComposeProvider`, `NetworkProvider`, `VolumeProvider`, `ContainersProvider`.
- **Services**: `ContainerService`.

## ADDED Requirements

### Requirement: Compose Management
The system SHALL allow users to create new Compose projects.
- **Scenario**: User taps FAB on "Orchestration" tab -> Shows "Create Compose" dialog/page -> User enters name and content -> Calls `/containers/compose`.

### Requirement: Network Management
The system SHALL allow users to create new networks.
- **Scenario**: User taps FAB on "Networks" tab -> Shows "Create Network" dialog -> User enters name, driver, subnet, gateway -> Calls `/containers/network`.

### Requirement: Volume Management
The system SHALL allow users to create new volumes.
- **Scenario**: User taps FAB on "Volumes" tab -> Shows "Create Volume" dialog -> User enters name, driver -> Calls `/containers/volume`.

### Requirement: Repository Management
The system SHALL allow users to create, edit, and delete image repositories.
- **Scenario**: User taps FAB on "Repositories" tab -> Shows form -> Calls `/containers/repo`.

### Requirement: Template Management
The system SHALL allow users to create, edit, and delete compose templates.
- **Scenario**: User taps FAB on "Templates" tab -> Shows form -> Calls `/containers/template`.

### Requirement: Configuration Management
The system SHALL allow users to edit and save `daemon.json`.
- **Scenario**: User taps "Edit" on "Config" tab -> Text area becomes editable -> User taps "Save" -> Calls `/containers/daemonjson/update`.
