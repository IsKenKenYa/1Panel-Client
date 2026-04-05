# Cross-Platform UI Governance

## Summary

This document defines how 1Panel Client should evolve from a single Flutter Material 3 UI baseline into a governed multi-design-system, multi-theme, and selectively native-capable product.

The goal is not to encourage arbitrary UI fragmentation. The goal is to keep one default cross-platform system, allow strong platform-native exceptions where they are valuable, and define a roadmap for introducing multiple visual systems without breaking architecture consistency.

## Current State

- The project currently uses `MaterialApp + ThemeData + dynamic_color`
- The default design language is Flutter Material Design 3
- There is no existing native UI registry, no platform-native page catalog, and no central design-system abstraction beyond the current theme controller
- Platform folders exist, but UI governance is still effectively Flutter-first
- Shared non-UI layers are still overwhelmingly Dart-based, including API access, models, providers, repositories, and infrastructure services
- The `桌面端适配` branch is a runnable desktop implementation branch and should be treated as valuable implementation reference material, not as an automatic replacement for the default baseline policy

## Default UI Rule

### Baseline

- The default UI baseline for all platforms is **Flutter/Dart + Material Design 3**
- Shared product pages should be implemented in Flutter first
- Material 3 remains the primary default for Android, shared desktop/mobile screens, and any feature without a strong platform-specific reason
- Shared non-UI layers must remain Dart-first and shared across platforms unless a hard system limitation requires otherwise

### Why this remains the default

- The current codebase, theme system, and widget hierarchy are already Flutter-centric
- Flutter already supports MD3 well, especially for Android
- Rewriting default Android MD3 in Kotlin/Compose would increase maintenance cost without equivalent product benefit

## Design Systems

The project may support multiple design systems over time, but they must be governed explicitly.

### Approved design-system families

- **Material Design 3**: default shared system
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

## Native UI Exceptions

Native UI is allowed, but only as an exception path with clear value.

### Apple platforms

Native SwiftUI pages are allowed when:

- Apple-native interaction patterns materially improve the experience
- the page benefits from Apple-specific visual idioms
- the page is strongly tied to Apple platform expectations

Examples may include settings, onboarding, or system-integration-heavy flows.

### Windows

Native WinUI3 / Fluent pages are allowed when:

- Windows-native shell integration or layout patterns are beneficial
- Fluent interaction and desktop affordances materially improve UX

### Android

Android defaults to Flutter Material 3.

Kotlin / Jetpack Compose native pages are allowed only when:

- platform/system APIs make Flutter integration awkward
- a system-heavy page benefits materially from native implementation
- there is a documented reason why Flutter adaptive UI is insufficient

Android native UI is not the default path for ordinary product pages.

## Page Categories

Every screen should conceptually fall into one of these categories:

### 1. Shared Flutter Screens

- implemented fully in Flutter
- use the default shared design system
- preferred for most product functionality

### 2. Platform-Adaptive Flutter Screens

- still implemented in Flutter
- adapt tokens, navigation, spacing, motion, or interaction by platform
- preferred before attempting native UI

### 3. Platform-Native Screens

- implemented in SwiftUI, WinUI3, Fluent-native, or exceptional Kotlin/Compose
- allowed only after explicit justification
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

## Roadmap

### Phase 1: Governance Baseline

- document the rules in `AGENTS.md`, `CLAUDE.md`, and this file
- treat Flutter MD3 as the default baseline
- require explicit approval for native exceptions

### Phase 2: Theme Abstraction

- evolve the current theme system toward a governed `DesignSystem` + `ThemeProfile` model
- centralize token mapping
- keep existing `ThemeController` and `AppTheme` as the starting point

### Phase 3: Flutter Adaptive Layer

- solve most platform differences inside Flutter first
- adapt spacing, navigation patterns, and tokens by platform where beneficial
- use the `桌面端适配` branch as runnable implementation reference material where helpful, but keep governance decisions in this document and the mainline repository rules

### Phase 4: Native Pilot Screens

- pilot one Apple-native page using SwiftUI
- pilot one Windows-native page using WinUI3 / Fluent
- only consider Android native pilot if there is a strong system-level reason

### Phase 5: Multi-Theme User Selection

- expand user-facing theme/style selection on top of the governed design-system model
- avoid uncontrolled style proliferation

## Repository Rules Summary

This document is detailed guidance.

The hard rules live in:

- `AGENTS.md`
- `CLAUDE.md`

Any changes to cross-platform UI governance must update all three locations together.
