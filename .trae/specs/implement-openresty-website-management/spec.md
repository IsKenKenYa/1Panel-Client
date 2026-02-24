# Website Management Module Adaptation Spec

## Why
The current Website Management module adaptation is incomplete. While basic API clients and models exist, the UI implementation is partial and contains compilation errors (e.g., `WebsiteInfo` missing `primaryDomain`, `OpenRestyPage` type mismatches). The integration with the backend via OpenResty, Domain, and SSL APIs needs to be verified against a live test server using the provided analysis tools.

## What Changes
- **Fix Compilation Errors**: Resolve `primaryDomain` vs `domain` property mismatch in `WebsiteInfo` and fix type errors in `OpenRestyPage`.
- **API Verification**: Use `analyze_module_api.py` to generate/verify API analysis for `website`, `openresty`, `ssl`, and `domain` (if applicable) to ensure full coverage.
- **Integration Testing**: Execute and refine existing API tests (`website_domain_api_client_test.dart`, `website_ssl_api_client_test.dart`, etc.) against the `.env` configured test server.
- **UI Implementation**:
  - **Website Detail**: Implement/Fix Configuration, Domain, and SSL management tabs with MDUI3.
  - **OpenResty**: Fix and finalize the Global Configuration UI.
- **Localization**: Ensure all new UI elements use `context.l10n`.

## Impact
- **Affected Specs**: `implement-openresty-website-management` (this spec replaces/extends it).
- **Affected Code**:
  - `lib/data/models/website_models.dart` (Model fixes)
  - `lib/features/websites/website_detail_page.dart` (UI fixes)
  - `lib/features/openresty/openresty_page.dart` (UI fixes)
  - `test/api_client/*` (Test execution)

## ADDED Requirements
### Requirement: API Consistency Verification
The system SHALL verify API consistency using `analyze_module_api.py` results.
- **Scenario**: Run analysis script
  - **WHEN** developer runs `analyze_module_api.py` for `website`, `openresty`, `ssl`
  - **THEN** generated JSONs must match implemented API clients.

### Requirement: Live Server Integration
The system SHALL pass integration tests against the server defined in `.env`.
- **Scenario**: Run integration tests
  - **WHEN** running `flutter test test/api_client/website_*.dart`
  - **THEN** all tests pass with real network requests (using `PANEL_BASE_URL` and `PANEL_API_KEY`).

## MODIFIED Requirements
### Requirement: Website Info Model
- **Change**: `WebsiteInfo` model MUST expose `domain` (or `primaryDomain` mapped to `domain`) to match UI usage and API response.
- **Reason**: Fix compilation error where UI expects `primaryDomain` but model has `domain`.

### Requirement: OpenResty Page Type Safety
- **Change**: `OpenRestyPage` MUST use correct types for `jsonDecode` and API calls.
- **Reason**: Fix `type 'String' is not a subtype of type 'Map<String, dynamic>'` and `toJson` errors.
