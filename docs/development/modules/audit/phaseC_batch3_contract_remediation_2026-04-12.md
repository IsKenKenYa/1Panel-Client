# Phase C Batch3 Contract Remediation (2026-04-12)

## 1) Automated Requirement Decomposition

- Added scanner: `docs/development/modules/deep_contract_drift_scan.py`
- Input baseline: `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`
- Output report: `docs/development/modules/audit/phaseC_batch3_deep_contract_scan_2026-04-12.json`

Initial deep scan summary:
- `path_missing`: 62
- `method_mismatch`: 6
- `body_missing`: 5

Selected high-confidence batch scope:
- Method mismatch:
  - `GET /toolbox/fail2ban/operate/sshd` (client) vs `POST` (swagger)
  - `GET /core/settings/upgrade/notes` (client) vs `POST` (swagger)
  - `GET /groups` (client) vs `POST` (swagger)
- Required body missing:
  - `POST /core/settings/upgrade`
  - `POST /settings/snapshot/recreate`
  - `POST /toolbox/ftp/sync`
  - `POST /databases/pg/:database/load`

## 2) Test Case Design

- Added contract red/green suite:
  - `test/api_client/phaseC_batch3_contract_alignment_test.dart`
- Cases: 7
  - 3 method-alignment checks
  - 4 required-body checks

## 3) Red Test Execution

Command:
- `flutter test test/api_client/phaseC_batch3_contract_alignment_test.dart`

Red result:
- `0 passed, 7 failed`
- Failures match expected drifts (method/body assertions)

## 4) Development Fixes

Updated files:
- `lib/api/v2/ssh_v2.dart`
  - `getFail2banSshdStatus`: `GET` -> `POST`, added body `{operate: status}`
- `lib/api/v2/update_v2.dart`
  - `systemUpgrade`: add body `{version: ...}`
  - `getUpgradeNotes`: `GET` -> `POST`, add body `{version: ...}`
- `lib/api/v2/website_group_v2.dart`
  - `getGroups`: `GET` -> `POST`, add body `{name, type}`
- `lib/api/v2/snapshot_v2.dart`
  - `recreateSnapshot`: add body `{id}`
- `lib/api/v2/toolbox_v2.dart`
  - `syncFtp`: add body `{ids}`
- `lib/api/v2/database_v2.dart`
  - `loadPostgresqlDatabaseFromRemote`: add required body `{database, from, type}`
- `lib/data/repositories/database_repository.dart`
  - pass `from/type` when calling PostgreSQL remote load

## 5) Unit Test Green Verification

Target suite command:
- `flutter test test/api_client/phaseC_batch3_contract_alignment_test.dart`

Result:
- `7 passed, 0 failed`

Repository unit gate command:
- `dart run test/scripts/test_runner.dart unit`

Result:
- Failed due unrelated pre-existing compile errors in `lib/api/v2/command_v2.dart`:
  - duplicate `getCommand` declaration
  - invalid `data` named argument on `GET` calls

## 6) Integration Verification

Command:
- `dart run test/scripts/test_runner.dart integration`

Result:
- Integration suite skipped by environment guard:
  - `RUN_LIVE_API_TESTS` not enabled

## Post-fix Deep Scan Delta

Re-run summary (`phaseC_batch3_deep_contract_scan_2026-04-12.json`):
- `method_mismatch`: `6 -> 3`
- `body_missing`: `5 -> 1`

Remaining notable candidate:
- `website_v2`: `GET /websites/lbs` still flagged for required body semantics in swagger (pending behavior confirmation before next batch)
