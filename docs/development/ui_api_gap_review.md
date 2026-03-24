# UI API Gap Review (UI-first parallel mode)

## Scope
- Source of truth: `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
- This document only tracks APIs needed by the revamped UI.
- Non-UI compile/test issues are intentionally out of scope for this review.

## Gap Table

| Module | Page Path | User Action | Required API | OpenAPI Path | Request Fields | Response Fields | Current Client Status | Temporary UI Degradation | Joint Acceptance Criteria |
|---|---|---|---|---|---|---|---|---|---|
| Server Metrics | `/home` -> Servers tab | Pull to refresh server cards | Load current metrics | `/dashboard/current/{ioOption}/{netOption}` | `ioOption`, `netOption` (path) | `current`, `avg`, `max`, `min`, metric points | ✅ `dashboard_v2.dart` implemented & tested | Show cards with config only and metric placeholders | After wiring, CPU/Memory/Load/Disk values visible in server cards |
| Server System Info | `/server-detail` | Open server details | Load server OS/base info | `/dashboard/base/os` | none | os/system detail fields | ✅ `dashboard_v2.dart` implemented & tested | Show URL/name and module grid | Server detail header displays API-based system info |
| File Browser | `/home` -> Files tab | Enter directory, list files | Search/list files | `/files/search` | `FileSearch` payload (`path`, `containSub`, etc.) | `[]FileInfo` | ✅ `file_v2.dart` has list/search methods | Placeholder list and actions | Path navigation + file list load from API |
| File Operations | `/home` -> Files tab | Upload/new file/new folder | Upload/create operations | `/files/upload`, `/files/create`, `/files/mkdir` (see OpenAPI) | operation payloads | operation result | ✅ `file_v2.dart` has upload, createDirectory methods | Buttons keep no-op placeholders | Button actions invoke API and render success/failure feedback |
| Dynamic Verification (MFA load) | `/home` -> Verification tab | Tap "Load MFA info" | Load MFA secret/QR | `/core/settings/mfa` | `code`, `interval`, `secret` (`dto.MfaCredential`) | `qrImage`, `secret` (`mfa.Otp`) | ✅ `setting_v2.dart` has `loadMfaInfo()` | Mock adapter returns local secret and empty qr | Real QR/secret loaded and rendered from API |
| Dynamic Verification (MFA bind) | `/home` -> Verification tab | Tap "Bind MFA" | Bind MFA | `/core/settings/mfa/bind` | `code`, `interval`, `secret` (`dto.MfaCredential`) | common success response | ✅ `setting_v2.dart` has `bindMfa()` | Mock adapter returns success immediately | API bind succeeds and UI status changes to enabled |
| Auth MFA Login | future login flow | Submit MFA code during login | MFA login | `/core/auth/mfalogin` | `dto.MFALogin` | login token/user info | ✅ `user_v2.dart` has `mfaLogin()` and `auth_v2.dart` has `mfaLogin()` | not consumed by UI revamp pages | End-to-end login with MFA available when auth UI is upgraded |

## Implementation Status Summary

### ✅ Completed API Clients (with tests)

| API Client | File | Test File | Status |
|------------|------|-----------|--------|
| Dashboard | `lib/api/v2/dashboard_v2.dart` | `test/api_client/dashboard_api_client_test.dart` | ✅ Tested |
| Container | `lib/api/v2/container_v2.dart` | `test/api_client/container_api_client_test.dart` | ✅ Tested |
| App | `lib/api/v2/app_v2.dart` | `test/api_client/app_api_client_test.dart` | ✅ Tested |
| Database | `lib/api/v2/database_v2.dart` | `test/api_client/database_api_client_test.dart` | ✅ Created |
| File | `lib/api/v2/file_v2.dart` | `test/api_client/file_api_client_test.dart` | ✅ Created |
| Website | `lib/api/v2/website_v2.dart` | `test/api_client/website_api_client_test.dart` | ✅ Created |
| Setting | `lib/api/v2/setting_v2.dart` | `test/api_client/setting_api_client_test.dart` | ✅ Tested (includes MFA) |
| User | `lib/api/v2/user_v2.dart` | - | ✅ Has MFA login |
| Auth | `lib/api/v2/auth_v2.dart` | - | ✅ Has MFA login |

### MFA Models Added

- `MfaCredential` - MFA凭证请求 (in `setting_models.dart`)
- `MfaOtp` - MFA OTP响应，包含 `qrImage` 和 `secret`
- `MfaBindRequest` - MFA绑定请求
- `MfaStatus` - MFA状态

## OpenAPI Notes Used in This Review
- `"/core/settings/mfa"` and `"/core/settings/mfa/bind"` definitions are present in V2 OpenAPI.
- `dto.MfaCredential` requires `code`, `interval`, `secret`.
- `mfa.Otp` exposes `qrImage` and `secret`.

## Implementation Contract for API Adapter Phase
- Keep `SecurityVerificationRepository` as the stable UI boundary.
- Implement a real repository adapter that maps:
  - `loadMfaInfo()` -> `/core/settings/mfa` ✅ Implemented in `setting_v2.dart`
  - `bindMfa()` -> `/core/settings/mfa/bind` ✅ Implemented in `setting_v2.dart`
- Do not change the UI page contract when replacing mock adapter; only replace repository binding.

## Test Runner Commands

```bash
# Run all API client tests
flutter test test/api_client/

# Run specific module tests
flutter test test/api_client/dashboard_api_client_test.dart
flutter test test/api_client/container_api_client_test.dart
flutter test test/api_client/setting_api_client_test.dart

# Run connection test
flutter test test/connection_test.dart
```
