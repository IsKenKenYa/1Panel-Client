## Background

Command module has an upstream contract drift for tree/list related endpoints.

- Swagger snapshot currently contains GET definitions for some endpoints.
- Runtime routing and existing web behavior indicate POST is required.

Based on module workflow and read-only upstream policy, this repo must close the gap on the client side first.

## Decision (current)

1. Keep client strategy strict: `POST` only, no `GET` fallback.
2. Runtime truth priority: Router/real API behavior > generated Swagger when conflict exists.
3. Keep upstream source read-only in this repo (`docs/OpenSource/1Panel/**`).

## Implemented scope

- API layer contract alignment in command client.
- Added list-route contract guards and regression tests.
- Updated command module docs with drift matrix and chain-sync blocking rules.
- Refreshed `command_api_analysis.*` from current swagger snapshot.

## Follow-up tasks

1. Track upstream issue status and switch back to unified contract once fixed.
2. Remove deprecated compatibility entry points after upstream contract stabilizes.
3. Keep API -> Repository -> Service -> Provider -> Page -> Tests -> Docs chain in sync for any future command endpoint updates.

## Acceptance criteria

- Full gate passes: analyze + unit + integration + ui.
- Command module docs include issue linkage and final contract verdict.
- No changes under `docs/OpenSource/1Panel/**` in this repo.
