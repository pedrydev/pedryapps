# AGENTS.md

## Project

All-in-one macOS utility app for everyday use. Known feature areas so far:

- Todos
- Notifications
- Calendar
- Additional utilities to be added over time

## Platform constraint

- macOS **only**. Do not add iOS, iPadOS, watchOS, tvOS, or cross-platform targets unless the user explicitly asks.
- Assume Apple silicon and current macOS as the primary deployment target unless stated otherwise.

## Status

Decided: macOS-only native app.

- Language: Swift 6
- UI: SwiftUI, with AppKit only where SwiftUI lacks a primitive
- Minimum deployment target: macOS 14 (Sonoma)
- Layout: one Xcode app target; source grouped as `App/`, `Domain/`, `Persistence/`, `Features/`, `Resources/`. No local Swift packages until a boundary is proven.
- Dependency manager: Swift Package Manager; no third-party dependencies by default
- Distribution: personal local use only; no App Store, sandbox, notarization, login item, or sync
- UI shape: window + global hotkey first; menu bar extra later
- Decisions and their rationale: `docs/adr/` globally; mini-app-specific ADRs under `docs/mini-apps/<mini-app>/adr/`
- All non-code artifacts produced by sessions live under `docs/`, split into one global set and one set per mini-app: global artifacts at `docs/<kind>/` (e.g. `docs/adr/`) plus `docs/GLOSSARY-MAP.md` and `docs/GLOSSARY.md`; mini-app artifacts at `docs/mini-apps/<mini-app>/` (e.g. `docs/mini-apps/todos/GLOSSARY.md`). Do not duplicate global content into mini-app folders. Do not create session feedback logs for this project.

## Working rules

- Focus only on the requested code. Do not refactor unrelated code.
- Prioritize correctness and clarity over cleverness. No unnecessary abstractions.
- Do not add comments unless the logic is non-obvious.
- No emojis.
- Never commit unless the user explicitly asks.
- Never skip hooks or bypass safety checks.
- If the requirement is ambiguous, ask before proceeding.

## Agent skills

### Issue tracker

Local markdown in `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default triage role names (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context (`GLOSSARY.md` + `docs/adr/`, plus per-mini-app glossaries under `docs/mini-apps/`). See `docs/agents/domain.md`.

## Workflow

Use only the skills vendored in `.agents/skills/`. Do not load skills from `~/.claude/skills`, `~/.config/opencode/skills`, or `~/.agents/skills`. If a global config names a skill that is not vendored here, this list takes precedence.

- Requirements and design: `grilling` or `grill-with-docs` for the decision tree; `domain-modeling` for terminology (`docs/GLOSSARY-MAP.md`, global and per-mini-app glossaries) and ADRs.
- Specs and tickets: `to-spec` and `to-tickets` when the work needs tracking; otherwise go straight from decisions to implementation.
- Implementation: `implement-spec` when working from a spec or ticket, `implement` otherwise. Use `tdd` where logic can be written test-first.
- Work too large for one session: `wayfinder` for the decision map, then resolve tickets one at a time; `handoff` when context needs transferring.
- Bugs: `diagnosing-bugs`. Review: `code-review` against the originating spec, ADR, or request.
- Optional: `prototype` to sanity-check state or UI, `research` for primary-source fact-finding, `codebase-design` when designing a module interface.

## Verification

- Typecheck/build: `xcodebuild -scheme PedryApps -destination 'platform=macOS' -configuration Debug build`
- Tests: `xcodebuild test -scheme PedryApps -destination 'platform=macOS'`
- Run both after changes.
- No lint command is configured yet; choose one when the project is created.
- If a verification command fails for environmental reasons, report it rather than skipping it.

## Project memory

Business rules, domain constraints, and invariants discovered during work are stored outside the repo in the project memory directory, not in this repository.
