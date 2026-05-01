# Cross-Platform UI Governance

## Summary

This document defines how 1Panel Client should evolve into a governed non-web multi-platform product with platform-specific UI strategies and a shared Dart business core.

The goal is not to encourage arbitrary UI fragmentation. The goal is to enforce one shared non-UI Dart core, allow multiple governed design systems/themes, and apply explicit platform strategies without breaking architecture consistency.

## Current State

- The project currently uses `MaterialApp + ThemeData + dynamic_color`
- macOS already has a native shell implementation baseline; platform parity is still evolving
- Render mode and theme preferences already exist, but cross-platform strategy mapping needs stronger governance
- Platform folders exist, but native parity and fallback evidence are not yet complete across all non-web targets
- Shared non-UI layers are still overwhelmingly Dart-based, including API access, models, providers, repositories, and infrastructure services
- The `桌面端适配` branch is a runnable desktop implementation branch and should be treated as valuable implementation reference material, not as an automatic replacement for the default baseline policy

## Default UI Rule

### Baseline

- Non-web target platforms are Android, iOS, iPadOS, macOS, Windows, Linux, and HarmonyOS (target phase)
- The project supports multiple design systems and multiple theme profiles under central governance
- MDUI3 is the mandatory, always-available baseline across target platforms and must not be treated as a backup-only path
- Apple (iOS/iPadOS/macOS) and Windows must keep a native UI track in parallel with the MDUI3 baseline
- Web is out of current adaptation scope
- Shared non-UI layers must remain Dart-first and shared across platforms unless a hard system limitation requires otherwise

### Why this is the default

- Different platforms have different UX priorities, so strategy must be platform-specific instead of one global native-first rule
- MDUI3 guarantees cross-platform continuity while native tracks can evolve without breaking shared delivery
- Shared Dart non-UI layers prevent duplicated business logic across design systems and UI stacks

## Design Systems

The project may support multiple design systems over time, but they must be governed explicitly.

### Approved design-system families

- **Material Design 3**: primary shared delivery path in current Android/Linux scope and general fallback system
- **Apple-style system**: allowed for Apple-native screens or Apple-priority visual modes
- **Fluent / WinUI3-style system**: allowed for Windows-native screens or Windows-priority visual modes

### Governance rule

A design system is not just a set of colors. A design system includes:

- visual tokens
- component behaviors
- motion style
- navigation patterns
- spacing and typography rules

No page may introduce an unregistered design system ad hoc.

## Theme System

The app should distinguish between **design systems** and **theme profiles**.

### Design system

The structural visual language:

- MD3
- Apple-style
- Fluent-style

### Theme profile

The end-user selectable appearance layer:

- light
- dark
- dynamic color
- brand seed color
- future user-selectable style presets

### Theme rule

User-facing theme switching is supported conceptually, but theme switching must remain centrally controlled.

The app should not allow individual pages to invent custom theming logic outside the shared theme system.

## Native UI Strategy

Native UI is governed by platform strategy and mandatory-track requirements for selected platforms.

### Apple platforms

SwiftUI-native pages are mandatory for iOS, iPadOS, and macOS track construction.
Visual direction should align with Liquid-Glass-like system aesthetics where appropriate.

Examples may include settings, onboarding, or system-integration-heavy flows.

### Windows

Native WinUI3 / Fluent pages are mandatory on Windows track construction.

### Android

Android defaults to Dart-rendered MDUI3 in the current phase.
Native pages are optional pilot paths and require explicit architecture review approval.

### Linux

Linux may deliver with Dart-rendered MDUI3 first in the current phase.
Native container capability can be introduced incrementally.

### HarmonyOS (target phase)

HarmonyOS remains in target scope with staged placeholders now and native milestone planning in roadmap phases.

Mandatory constraints:

- native and MDUI3 modes must share the same Dart non-UI core
- no duplicated business rules between native and MDUI3 presentation stacks
- platform-native UX enhancements must preserve shared state/service/repository contracts

## Future Platform Placeholder (HarmonyOS)

HarmonyOS and other future platforms are handled as staged placeholders in this phase:

- reserve `UiTarget`/routing placeholders in Dart
- reserve channel/provider placeholders for bridge boundaries
- do not commit full native UI delivery yet, while keeping it in the long-term target scope
- do not move shared business logic into future platform native layers

## Page Categories

Every screen should conceptually fall into one of these categories:

### 1. Shared Flutter Screens

- implemented fully in Flutter
- use the shared MDUI3 baseline design system
- preferred as cross-platform baseline implementation

### 2. Platform-Adaptive Flutter Screens

- still implemented in Flutter
- adapt tokens, navigation, spacing, motion, or interaction by platform
- preferred when native shells are unavailable or still under parity implementation

### 3. Platform-Native Screens

- implemented in SwiftUI, WinUI3, Fluent-native, or exceptional Kotlin/Compose
- preferred for non-web targets once shared Dart non-UI contracts are in place
- must preserve application layering and shared business logic contracts

## Native Bridge Boundaries

Native UI does not change architectural boundaries.

### Mandatory rules

- Native UI must not directly call `lib/api/v2/`
- Native UI must not own core business logic
- Native UI must consume shared state/service/repository boundaries through controlled bridges
- Presentation still flows into State, then Service/Repository, then API/Infra
- API clients, shared models, repositories, providers, and most application services should continue to be implemented in Dart unless there is a hard platform restriction

### Practical implication

If a native page is introduced, it should be treated as a presentation container, not as a separate business stack.
If native code is added, the burden of proof is on the native layer to justify why the same result cannot be achieved through Flutter UI adaptation plus shared Dart logic.

### Windows capability whitelist (Phase 2-3)

- Windows native bridge channel: `onepanel/windows_bridge`
- Bridge-owned capabilities currently enabled:
	- `windowCommands` (minimize / maximize / restore / close)
	- `alwaysOnTop` (toggle topmost)
- `tray` and `toast` are enabled in Phase 3 with explicit permission flags:
	- `toastPermissionGranted`
	- `trayPermissionGranted`
- Toast failure strategy:
	- if native toast path fails or toast permission is denied, fallback to tray balloon notification when tray permission is granted
- Declared but not enabled capabilities (must stay disabled until dedicated implementation and review):
	- `systemBackdrop`
	- `jumpList`
	- `fileAssociation`
- Boundary rule: Flutter side can only call whitelisted commands through `WindowsShellBridge`; arbitrary command names and direct native invocation are prohibited.
- Validation baseline: run `scripts/windows/run_windows_bridge_validation.ps1` for command return and window-state assertions.

## Desktop Shell Stability

Desktop shells keep modules alive longer than mobile shells, so UI stability rules must be stricter.

### Hero and FAB policy

- Cached module pages in desktop shells must disable Hero participation when inactive
- Pages using `FloatingActionButton` must set explicit `heroTag` values unless Hero is intentionally disabled
- Never rely on Flutter's default FAB hero tag in a desktop shell that can keep multiple pages alive simultaneously

### Recursive widget construction policy

- Do not reassign mutable widget variables and then feed the current value back into a child/builder path
- Prefer explicit staged variables such as `baseContent`, `interactiveContent`, and `draggableContent`
- Any desktop drag/drop or context-menu wrapping should be reviewed for self-referential widget composition

## Component and Token Governance

Before multiple design systems are implemented, the codebase should move toward semantic component and token abstraction.

### Required direction

- define semantic tokens before multiplying design systems
- map tokens by system instead of hardcoding page-level visual choices
- prefer reusable cross-platform component shells

### Prohibited pattern

- page-by-page isolated styling rules with no central mapping
- arbitrary per-page platform styling decisions without documentation

## Review Checklist

Any PR introducing a new visual system, native page, or platform-specific UI should answer:

1. Is Flutter adaptive UI insufficient here?
2. Which category is this page: shared, adaptive, or native?
3. Which design system does it belong to?
4. Which tokens/components are shared vs platform-specific?
5. Does it preserve `Presentation -> State -> Service/Repository -> API/Infra`?
6. What is the fallback or rollback plan?
7. Is the plan aligned with platform strategy mapping (Windows native, Apple native, Android/Linux MDUI3-first, Harmony placeholder)?
8. Does the change preserve the mandatory dual-track requirement (MDUI3 baseline + native track) for Apple and Windows?

## Roadmap

### Phase 1: Governance Baseline

- document the rules in `AGENTS.md`, `CLAUDE.md`, and this file
- treat platform strategy mapping + shared Dart business core as baseline
- require explicit parity checklist and fallback evidence per platform

### Phase 2: Theme Abstraction

- evolve the current theme system toward a governed `DesignSystem` + `ThemeProfile` model
- centralize token mapping
- keep existing `ThemeController` and `AppTheme` as the starting point

### Phase 3: Flutter Adaptive Layer

- use MDUI3 as shared rendering baseline for Android/Linux and controlled fallback for other targets
- adapt spacing, navigation patterns, and tokens by platform where beneficial
- use the `桌面端适配` branch as runnable implementation reference material where helpful, but keep governance decisions in this document and the mainline repository rules

### Phase 4: Native Pilot Screens

- maintain parity checklist for Apple and Windows mandatory native tracks
- continue incremental Linux native-shell exploration while keeping MDUI3 as the current delivery baseline
- preserve Harmony placeholder routing/channel/provider contracts and execute native milestone planning

### Phase 5: Multi-Theme User Selection

- expand user-facing theme/style selection on top of the governed design-system model
- avoid uncontrolled style proliferation

## Repository Rules Summary

This document is detailed guidance.

The hard rules live in:

- `AGENTS.md`
- `CLAUDE.md`

Any changes to cross-platform UI governance must update all three locations together.

Operational workflow references:

- `docs/模块适配专属工作流.md`
- `docs/原生UI适配专属工作流.md`
