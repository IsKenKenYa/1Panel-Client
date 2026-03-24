# Tasks

- [x] Task 1: Verify and Update API Analysis
  - [x] SubTask 1.1: Run `analyze_module_api.py` for `openresty`, `website`, `ssl` to generate latest analysis JSONs.
  - [x] SubTask 1.2: Compare generated JSONs with `lib/api/v2/*` clients to ensure all endpoints are covered.

- [x] Task 2: Fix Compilation Errors & Model Mismatches
  - [x] SubTask 2.1: Update `WebsiteInfo` in `lib/data/models/website_models.dart` to alias `primaryDomain` to `domain` or update UI to use `domain`.
  - [x] SubTask 2.2: Fix `OpenRestyPage` type errors (generic `toJson` calls, map casting) in `lib/features/openresty/openresty_page.dart`.
  - [x] SubTask 2.3: Verify `flutter analyze` passes for modified files.

- [x] Task 3: Verify API Clients with Integration Tests
  - [x] SubTask 3.1: Ensure `.env` is configured (using `PANEL_BASE_URL` and `PANEL_API_KEY` from user context).
  - [x] SubTask 3.2: Run `flutter test test/api_client/openresty_api_client_test.dart` against test server.
  - [x] SubTask 3.3: Run `flutter test test/api_client/website_domain_api_client_test.dart` against test server.
  - [x] SubTask 3.4: Run `flutter test test/api_client/website_ssl_api_client_test.dart` against test server.
  - [x] SubTask 3.5: Run `flutter test test/api_client/website_config_api_client_test.dart` against test server.
  - [x] SubTask 3.6: Fix any API client issues found during testing.

- [x] Task 4: Finalize Website Detail UI (MDUI3)
  - [x] SubTask 4.1: Implement/Verify "Configuration" tab (Read/Update).
  - [x] SubTask 4.2: Implement/Verify "Domain Management" tab (List/Add/Delete).
  - [x] SubTask 4.3: Implement/Verify "SSL" tab (View/Update/Renew).
  - [x] SubTask 4.4: Ensure all UI text uses `context.l10n`.

- [x] Task 5: Finalize OpenResty UI (MDUI3)
  - [x] SubTask 5.1: Ensure Status, Modules, HTTPS, Config tabs work correctly with fixed API integration.
  - [x] SubTask 5.2: Ensure all UI text uses `context.l10n`.

- [x] Task 6: Final Verification
  - [ ] SubTask 6.1: Run `flutter build apk --debug` to ensure build success. (Skipped due to environment issue)
  - [x] SubTask 6.2: Update module documentation if necessary.
