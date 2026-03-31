# Security Policy

## Supported Versions

Security fixes are prioritized on actively maintained branches and current preview releases.

## Reporting a Vulnerability

Please do **not** disclose vulnerabilities publicly before triage.

Report via:

- GitHub Security Advisories (preferred), or
- GitHub Issues when advisory is unavailable: https://github.com/IsKenKenYa/1Panel-Client/issues

Include:

- affected version/commit
- reproduction steps
- impact assessment
- optional mitigation suggestions

## Response Goals

- Acknowledge report as soon as practical
- Validate and triage severity
- Fix high-impact issues with priority
- Credit reporters where appropriate

## Secure Development Notes

- Do not log secrets (API keys/passwords/private tokens)
- Use `appLogger` instead of `print`/`debugPrint`
- Keep dependencies updated and reviewed
- Follow least-privilege permission usage

