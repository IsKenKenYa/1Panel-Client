# Refine App & Container Management Spec

## Status
Pending

## Why
Analysis of the `1PanelV2OpenAPI` and current implementation reveals gaps in "App Management" and "Container Management" modules. While basic CRUD is present, advanced but essential operations (Rename, Upgrade, Commit for Containers; Tag, Push, Save for Images; Sync for Apps) are missing from the UI despite being supported by the API/Service layer.

## What Changes

### 1. Container Management Enhancements
- **Container List (`ContainersPage`)**:
    - Add a **"More" (three-dot) menu** to each Container item in the list.
    - Menu items: **Rename**, **Upgrade**, **Edit (Update)**, **Commit**.
    - Add **"Prune"** action to the AppBar (cleans stopped containers/unused images).
- **Dialogs**:
    - `RenameContainerDialog`: Input new name.
    - `UpgradeContainerDialog`: Confirm image pull and recreation.
    - `CommitContainerDialog`: Input image name/tag, author, message.
    - `EditContainerDialog`: Edit CPU/Memory limits (using `updateContainer`).

### 2. Image Management Enhancements
- **Image List (`ImagePage`)**:
    - Add a **"More"** menu to `ImageCard`.
    - Menu items: **Tag**, **Push**, **Save**.
- **Dialogs**:
    - `TagImageDialog`: Input repo/tag.
    - `PushImageDialog`: Confirm push.
    - `SaveImageDialog`: Input filename (or just confirm download).

### 3. App Management Enhancements
- **App Store (`AppStorePage`)**:
    - Add **"Sync"** button to AppBar to sync app list from remote.
- **Installed App Detail (`InstalledAppDetailPage`)**:
    - Add **"Ignore Update"** option (e.g., in the Update dialog or as a separate action).

## Impact
- **UI**: `ContainerCard`, `ImageCard`, `ContainersPage`, `AppStorePage`, `InstalledAppDetailPage`.
- **New Dialogs**: `RenameContainerDialog`, `CommitContainerDialog`, `TagImageDialog`, etc.
- **Providers**: `ContainersProvider`, `DockerImageProvider`, `AppStoreProvider`.

## Requirements

### Requirement: Container Advanced Actions
The system SHALL allow users to Rename, Upgrade, Edit, and Commit containers from the list view.
- **Scenario**: User taps "More" on a container -> Selects "Rename" -> Enters new name -> Confirms -> Container renamed.

### Requirement: Image Advanced Actions
The system SHALL allow users to Tag, Push, and Save images.
- **Scenario**: User taps "More" on an image -> Selects "Tag" -> Enters new tag -> Confirms.

### Requirement: App Sync
The system SHALL allow users to manually sync the App Store list.
- **Scenario**: User taps "Sync" in App Store -> System fetches latest app list.
