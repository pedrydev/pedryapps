# AGENTS.md

## Project

All-in-one macOS utility app for everyday use. Known feature areas so far:

- Todos
- Notifications
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
- Never skip hooks or bypass safety checks.
- If the requirement is ambiguous, ask before proceeding.

## Agent skills

### Issue tracker

GitHub Issues in `pedrydev/pedryapps`. See `docs/agents/issue-tracker.md`. When every child issue of a parent is closed, close the parent immediately.

### Triage labels

Default triage role names (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context (`GLOSSARY.md` + `docs/adr/`, plus per-mini-app glossaries under `docs/mini-apps/`). See `docs/agents/domain.md`.

## Workflow

Use only the skills vendored in `.agents/skills/`. Do not load skills from `~/.claude/skills`, `~/.config/opencode/skills`, or `~/.agents/skills`. If a global config names a skill that is not vendored here, this list takes precedence. Treat vendored skills as read-only: skill updates overwrite local edits. This file overrides any conflicting skill instruction, including `implement`'s default to commit.

- Sequence: **make it work**, then **make it work well**. Bank quality ideas during implementation; apply them in the quality pass.
- Requirements and design: `grilling` or `grill-with-docs` for the decision tree; `domain-modeling` for terminology (`docs/GLOSSARY-MAP.md`, global and per-mini-app glossaries) and ADRs.
- Specs and tickets: never go directly to implementation. A spec and one or more tickets must exist before any implementation starts. If the task is trivial, ask the user whether to skip these artifacts and proceed only after explicit approval — never decide unilaterally.
- Implementation: `implement-spec` when working from a spec or ticket. Speed first: smallest change that compiles and passes tests; build for feedback, full verification at each AC gate. Use `tdd` where logic can be written test-first.
- Work too large for one session: `wayfinder` for the decision map, then resolve tickets one at a time; `handoff` when context needs transferring.
- Bugs: `diagnosing-bugs`.
- Optional: `prototype` to sanity-check state or UI, `research` for primary-source fact-finding, `codebase-design` when designing a module interface.

### Ticket execution: mandatory gates

One ticket at a time. Every step below is a **gate** with a completion criterion; the next gate starts only when the current one is met. If a gate fails, stay on it until it passes, or stop and report if blocked. No other order is valid.

1. **Pick ticket.** Choose an issue whose parent issue refers to the associated spec. Gate complete when the ticket, its parent, and the spec are in context.
2. **List acceptance criteria.** Put every AC from the ticket into a numbered working checklist; a ticket has at least one AC. Gate complete when every AC is numbered and none are implied.
3. **Run the AC loop**, in checklist order. For each AC, complete all six gates before starting the next AC:
   1. **Test suite:** add or extend tests that fail for this AC.
   2. **Implement fast:** smallest change that makes this AC pass and compiles.
   3. **Pass tests:** run build and test commands; green only.
   4. **Code review with skills:** `code-review` against the spec, ADR, and ticket; then load the vendored Swift skills matching the diff — `write-swift`, `swiftui-pro`, `swift-testing-expert`, `swift-format-style`, `swiftui-design-principles`, plus `app-intents` / `background-execution` / `widgets` when those frameworks are touched — apply their improvements to changed files only, report them under `## Swift quality`, and re-run verification.
   5. **Lint:** `swift format lint --recursive src tests --strict`; clean.
   6. **Commit:** exactly one commit holding only this AC's changes; the message names the AC. Gate complete when the commit exists and its checklist entry is marked done.
   
   Ask me for a manual test whenever one is useful; asking after the AC commit is fine.
4. **Close out the ticket.** Only after every checklist entry is committed: pull the latest `master`, push the ticket branch, open a PR to `master` whose body links the ticket and its parent issue, and wait for merge. Then comment the explanation and close the ticket; close the parent immediately when its last child is closed. Delete the merged branch locally and on the remote. Gate complete when the PR is merged and the ticket is closed.

## Verification

- Typecheck/build: `xcodebuild -scheme PedryApps -destination 'platform=macOS' -configuration Debug build`
- Tests: `xcodebuild test -scheme PedryApps -destination 'platform=macOS'`
- Run both at every AC's **Pass tests** gate.
- Lint: `swift format lint --recursive src tests --strict`
- If a verification command fails for environmental reasons, report it rather than skipping it.
- Commit at the AC's **Commit** gate, not at the end of the ticket. Manual verification counts as a test; ask me for it when a change needs it.

## Project memory

Business rules, domain constraints, and invariants discovered during work are stored outside the repo in the project memory directory, not in this repository.
