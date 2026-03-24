# UI Revamp Notes (UI-first, API-parallel)

## Goal
- Prioritize UI restructuring and i18n standardization.
- Keep runtime flows usable even when API clients are under parallel adaptation.
- Record API gaps in `ui_api_gap_review.md` for follow-up.

## Major Changes

### 1) New Application Shell
- Introduced a 4-tab shell architecture:
  - Servers
  - Files
  - Dynamic Verification
  - Settings
- Legacy routes are redirected to the new shell or a legacy redirect page.

### 2) Server Main Flow
- Added card-based server list UI.
- Added modular server detail page with quick actions and module entry grid.
- Kept server config management via local API config storage.

### 3) Files and Settings Refresh
- Rebuilt files and settings pages under the same visual language.
- Files page is intentionally UI-ready with placeholders until file client wiring is complete.
- Settings page now contains theme/language selectors and onboarding reset action.

### 4) Dynamic Verification Page
- Implemented UI flow for MFA loading/binding via repository abstraction.
- Current default uses mock repository to avoid blocking on in-progress API clients.

### 5) Onboarding
- Added 3-step full-screen onboarding page.
- Added coach-mark overlay for first-run key actions on server page.
- Added persistence keys for onboarding/coach completion.

### 6) Internationalization (ARB)
- Added `l10n.yaml` and ARB resources (`app_en.arb`, `app_zh.arb`).
- Migrated new UI flows to generated localization resources.
- Added `BuildContext` l10n extension for clean usage.

### 7) Theme and Tokens
- Added design tokens (`app_design_tokens.dart`).
- Unified Material 3 light/dark themes with consistent shape/spacing behavior.
- Reserved extension points for future iOS-specific visual treatment.

## Changed/New Files
- `lib/main.dart`
- `lib/config/app_router.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`
- `l10n.yaml`
- `lib/core/i18n/l10n_x.dart`
- `lib/core/theme/app_design_tokens.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/services/app_preferences_service.dart`
- `lib/core/services/app_settings_controller.dart`
- `lib/core/services/onboarding_service.dart`
- `lib/features/shell/app_shell_page.dart`
- `lib/features/server/server_models.dart`
- `lib/features/server/server_repository.dart`
- `lib/features/server/server_provider.dart`
- `lib/features/server/server_list_page.dart`
- `lib/features/server/server_detail_page.dart`
- `lib/features/server/server_form_page.dart`
- `lib/features/security/security_repository.dart`
- `lib/features/security/security_provider.dart`
- `lib/features/security/security_verification_page.dart`
- `lib/features/onboarding/onboarding_page.dart`
- `lib/features/onboarding/coach_mark_overlay.dart`
- `lib/features/files/files_page.dart`
- `lib/pages/settings/settings_page.dart`
- `lib/pages/server/server_selection_page.dart`
- `lib/pages/server/server_config_page.dart`
- `lib/widgets/navigation/app_bottom_navigation_bar.dart`
- `lib/widgets/navigation/app_drawer.dart`
- `docs/development/ui_api_gap_review.md`
- `docs/development/ui_revamp_notes.md`

## Important Constraints Kept
- Non-UI historical compile problems were not globally fixed in this round.
- API source-of-truth was constrained to `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`.
- Missing API integrations are isolated behind UI-side abstractions.
