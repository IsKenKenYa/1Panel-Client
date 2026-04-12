# Cross-Platform UI Governance

## Summary

This document defines how 1Panel Client should evolve into a governed non-web multi-platform product with dual UI systems: platform-native UI first and MDUI3 fallback.

The goal is not to encourage arbitrary UI fragmentation. The goal is to enforce one shared non-UI Dart core, keep native UI as the non-web default, provide a controlled MDUI3 fallback, and define a roadmap for platform parity without breaking architecture consistency.

## Current State

- The project currently uses `MaterialApp + ThemeData + dynamic_color`
- macOS already has a native shell implementation baseline; iOS/Windows/Linux native shells are still incomplete
- Render mode (`native` / `md3`) already exists in settings and preferences, but runtime fallback strategy needs stronger governance
- Platform folders exist, but native parity and fallback evidence are not yet complete across all non-web targets
- Shared non-UI layers are still overwhelmingly Dart-based, including API access, models, providers, repositories, and infrastructure services
- The `桌面端适配` branch is a runnable desktop implementation branch and should be treated as valuable implementation reference material, not as an automatic replacement for the default baseline policy

## Default UI Rule

### Baseline

- The default UI baseline for all **non-web** platforms is **platform-native UI**
- MDUI3 is the shared fallback rendering layer and must remain switchable at runtime
- Web is out of current adaptation scope
- Shared non-UI layers must remain Dart-first and shared across platforms unless a hard system limitation requires otherwise

### Why this is the default

- Platform-native interaction quality is a core product goal for desktop and mobile targets
- Runtime MDUI3 fallback keeps delivery safe while native parity is being completed
- Shared Dart non-UI layers prevent duplicated business logic across native and MDUI3 modes

## Design Systems

The project may support multiple design systems over time, but they must be governed explicitly.

### Approved design-system families

- **Material Design 3**: default fallback/shared rendering system
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

Native UI is the non-web default strategy, not an exception.

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

Android defaults to native UI (including Kotlin/Compose) with switchable MDUI3 fallback.

Mandatory constraints:

- native and MDUI3 modes must share the same Dart non-UI core
- no duplicated business rules between native and MDUI3 presentation stacks
- platform-native UX enhancements must preserve shared state/service/repository contracts

## Future Platform Placeholder (HarmonyOS)

HarmonyOS and other future platforms are handled as staged placeholders in this phase:

- reserve `UiTarget`/routing placeholders in Dart
- reserve channel/provider placeholders for bridge boundaries
- do not commit full native UI delivery yet
- do not move shared business logic into future platform native layers

## Page Categories

Every screen should conceptually fall into one of these categories:

### 1. Shared Flutter Screens

- implemented fully in Flutter
- use the shared MDUI3 fallback design system
- preferred as fallback path and cross-platform backup implementation

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
- treat non-web native-first + MDUI3 fallback as baseline
- require explicit parity checklist and fallback evidence per platform

### Phase 2: Theme Abstraction

- evolve the current theme system toward a governed `DesignSystem` + `ThemeProfile` model
- centralize token mapping
- keep existing `ThemeController` and `AppTheme` as the starting point

### Phase 3: Flutter Adaptive Layer

- use MDUI3 as controlled fallback and shared rendering baseline
- adapt spacing, navigation patterns, and tokens by platform where beneficial
- use the `桌面端适配` branch as runnable implementation reference material where helpful, but keep governance decisions in this document and the mainline repository rules

### Phase 4: Native Pilot Screens

- complete parity checklist for macOS native shell
- pilot iOS-native shell and Windows-native shell baselines
- establish Linux-native shell baseline while keeping MDUI3 fallback
- reserve Harmony placeholder routing/channel/provider contracts

### Phase 5: Multi-Theme User Selection

- expand user-facing theme/style selection on top of the governed design-system model
- avoid uncontrolled style proliferation

## Repository Rules Summary

This document is detailed guidance.

The hard rules live in:

- `AGENTS.md`
- `CLAUDE.md`

Any changes to cross-platform UI governance must update all three locations together.
