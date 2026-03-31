# Logging and Data Retention Policy

Last updated: 2026-03-31

## 1. Scope

This policy describes application logging behavior for 1Panel Client.

## 2. Logging Channels

- Console output (for development/runtime diagnostics)
- Local file logs (app logger file output)

## 3. Log Content

Logs are intended for diagnostics and operations tracking.
They should avoid sensitive secrets (passwords, raw tokens, private keys).  
When adding new logs, developers must keep messages minimal and desensitized.

## 4. Log Levels

- Trace / Debug: development diagnostics
- Info: operation milestones and state changes
- Warning / Error / Fatal: abnormal states and failures

## 5. Storage and Retention

- Logs are persisted locally with size-based rotation.
- Old logs are automatically cleaned by retention policy.
- Current default retention period: 30 days.

## 6. User Export

- Users can export local diagnostic logs.
- Export is user-triggered and stored locally on device filesystem.

## 7. User Deletion

- Users can clear local logs.
- Automatic cleanup also removes expired logs.

## 8. Compliance Notes

If remote telemetry/crash upload is introduced in future versions, related consent and disclosure must be updated in privacy documents before release.

