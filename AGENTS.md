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

The repository is empty and the tech stack is **not yet decided**. Confirm the stack with the user before writing any implementation code. Record the decision here once made (language, UI framework, minimum macOS version, project/package layout, dependency manager).

## Working rules

- Focus only on the requested code. Do not refactor unrelated code.
- Prioritize correctness and clarity over cleverness. No unnecessary abstractions.
- Do not add comments unless the logic is non-obvious.
- No emojis.
- Never commit unless the user explicitly asks.
- Never skip hooks or bypass safety checks.
- If the requirement is ambiguous, ask before proceeding.

## Workflow

- For tasks that do not decompose into independent units: use the single-agent pipeline (`business-analyst` → `architect` → `unit-tester` → `implementer` → `validator`) via the corresponding skills.
- For features or epics spanning multiple independent tasks: use the multi-agent pipeline (`orchestrator` → `worker` → `validator`).
- Load the `implementer` skill for any implementation task so work proceeds layer by layer, innermost to outermost, with test-verify-refactor loops and a checkpoint per layer.
- Load `architect` for major design decisions; load `blazor` only if a Blazor-based stack is chosen.

## Verification

- Run the project's lint and typecheck commands after changes. These commands are unknown until the stack is chosen; add them here once established.
- If no verification command exists, ask the user for one and add it here.

## Project memory

Business rules, domain constraints, and invariants discovered during work are stored outside the repo in the project memory directory, not in this repository.
