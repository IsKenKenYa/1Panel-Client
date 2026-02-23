# Tasks

- [ ] Task 1: Update ContainersPage FAB Logic
  - [ ] SubTask 1.1: Modify `_buildFloatingActionButton` in `ContainersPage` to render appropriate buttons for Compose, Network, Volume, Repo, and Template tabs.

- [ ] Task 2: Enhance Compose Tab
  - [ ] SubTask 2.1: Create `ComposeCreateDialog` or page.
  - [ ] SubTask 2.2: Implement `createCompose` in `ComposeProvider` and `ContainerService`.
  - [ ] SubTask 2.3: Integrate creation flow into `ComposePage` (via `ContainersPage` FAB or internal).

- [ ] Task 3: Enhance Network Tab
  - [ ] SubTask 3.1: Create `NetworkCreateDialog`.
  - [ ] SubTask 3.2: Implement `createNetwork` in `NetworkProvider` and `ContainerService`.
  - [ ] SubTask 3.3: Integrate creation flow into `NetworkPage` (via `ContainersPage` FAB).

- [ ] Task 4: Enhance Volume Tab
  - [ ] SubTask 4.1: Create `VolumeCreateDialog`.
  - [ ] SubTask 4.2: Implement `createVolume` in `VolumeProvider` and `ContainerService`.
  - [ ] SubTask 4.3: Integrate creation flow into `VolumePage` (via `ContainersPage` FAB).

- [ ] Task 5: Enhance Repositories Tab
  - [ ] SubTask 5.1: Create `RepoCreateDialog` (handling Create and Edit).
  - [ ] SubTask 5.2: Implement `createRepo`, `updateRepo`, `deleteRepo` in `ContainersProvider` (or new `RepoProvider`).
  - [ ] SubTask 5.3: Update `ReposTab` to support Create (FAB), Edit/Delete (ListTile actions).

- [ ] Task 6: Enhance Templates Tab
  - [ ] SubTask 6.1: Create `TemplateCreateDialog` (handling Create and Edit).
  - [ ] SubTask 6.2: Implement `createTemplate`, `updateTemplate`, `deleteTemplate` in `ContainersProvider` (or new `TemplateProvider`).
  - [ ] SubTask 6.3: Update `TemplatesTab` to support Create (FAB), Edit/Delete (ListTile actions).

- [ ] Task 7: Enhance Config Tab
  - [ ] SubTask 7.1: Modify `ConfigTab` to support "Edit" mode.
  - [ ] SubTask 7.2: Implement `updateDaemonJson` in `ContainersProvider` and `ContainerService`.
  - [ ] SubTask 7.3: Bind "Save" action to API call.

# Task Dependencies
- Task 1 is prerequisite for UI integration of creation tasks (or can be done in parallel if using page-local FABs, but `ContainersPage` controls the main Scaffold).
- Service/Provider updates (SubTasks x.2) should be done before UI integration.
