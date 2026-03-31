# Contributing Guide

Thank you for contributing to 1Panel Client.

## Before You Start

- Read `AGENTS.md` and `CLAUDE.md` for project standards.
- Keep changes focused and small.
- Follow layered architecture and logging conventions.

## Development Baseline

Run before submitting:

- `flutter analyze`
- `dart run test_runner.dart unit`
- run `integration` tests if API/network or data-write behavior is changed
- run `ui` tests if UI is changed

## Coding Rules

- Use `appLogger`; do not use `print()`/`debugPrint()`.
- Keep dependency direction clean: Presentation -> State -> Service/Repository -> API/Infra.
- Avoid business logic in widget `build()`.
- Respect file size limits from `AGENTS.md`/`CLAUDE.md`.

## Pull Request Checklist

- clear description and motivation
- test results included
- screenshots for UI changes
- docs updated when behavior/policy changed
- no secrets in code or logs

## License

By contributing, you agree your contributions are licensed under GPL-3.0 with the rest of this repository.

