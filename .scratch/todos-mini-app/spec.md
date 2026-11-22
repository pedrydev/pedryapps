Status: ready-for-agent

# Todos Mini-App Spec

## Problem Statement

I need a simple, reliable place on my Mac to capture personal to-dos as they come up, see them in one flat list, note the day I plan to work on each one, keep that list in the order I care about, and remove items when I have checked them off. I do not want a heavyweight task manager; I want a lightweight personal list that is immediately available in the app and still there after I quit and reopen it.

## Solution

Provide a Todos mini-app that shows a single flat list of Todos. I can add a Todo with a do-on date, see all current Todos with their do-on dates, change a do-on date, reorder them, and check off a Todo to remove it from the list permanently. The Todos mini-app persists its own data locally as its own document so the list survives app restarts, while keeping the domain model independent from persistence concerns.

## User Stories

1. As a Mac user, I want to open the Todos mini-app, so that I can see my personal to-dos in one place.
2. As a Mac user, I want to see a single flat list of Todos, so that I do not have to navigate projects, folders, or nested lists.
3. As a Mac user, I want to see an empty state when there are no Todos, so that I understand the list is empty and I can add my first Todo.
4. As a Mac user, I want to add a Todo by entering text, so that I can quickly capture something I need to do.
5. As a Mac user, I want the add action to be quick and obvious, so that capturing a Todo does not interrupt my flow.
6. As a Mac user, I want empty or whitespace-only Todo text to be rejected, so that I do not create meaningless Todos.
7. As a Mac user, I want newly added Todos to appear in a predictable position in the list, so that I know where to find what I just captured.
8. As a Mac user, I want each Todo to show its text clearly, so that I can scan the list quickly.
9. As a Mac user, I want to check off a Todo, so that I can mark it as done.
10. As a Mac user, I want a checked-off Todo to be removed from the list permanently, so that my list only contains active Todos.
11. As a Mac user, I want check-off to happen with minimal friction, so that completing Todos feels fast.
12. As a Mac user, I want the check-off action to be unambiguous, so that I understand checking off removes the Todo rather than archiving it.
13. As a Mac user, I want to reorder Todos, so that the list reflects my current priority.
14. As a Mac user, I want reordering to preserve every Todo's identity and text, so that changing order does not corrupt or duplicate items.
15. As a Mac user, I want the list order to persist across app restarts, so that my priorities remain stable.
16. As a Mac user, I want Todos to persist after I quit and reopen the app, so that I do not lose my list.
17. As a Mac user, I want adding a Todo to be persisted, so that a newly captured Todo is not lost if the app closes.
18. As a Mac user, I want checking off a Todo to be persisted, so that removed Todos do not reappear after restart.
19. As a Mac user, I want reordering Todos to be persisted, so that my chosen order is durable.
20. As a Mac user, I want the Todos mini-app to load its saved data when it appears, so that I always see the current list.
21. As a Mac user, I want the Todos mini-app to handle a missing saved document by starting with an empty list, so that first launch works without setup.
22. As a Mac user, I want the Todos mini-app to own its own persisted document, so that future mini-apps do not couple their data to Todos.
23. As a Mac user, I want the Todos mini-app to use plain domain data, so that the core model remains understandable and independent of persistence framework details.
24. As a Mac user, I want Todo mutations to be serialized through one store, so that the list does not get corrupted by concurrent writes.
25. As a Mac user, I want the UI to reflect store changes immediately, so that I can trust what I see after adding, checking off, or reordering.
26. As a Mac user, I want the Todos mini-app to be usable with keyboard and pointer interactions appropriate for macOS, so that I can manage Todos naturally.
27. As a Mac user, I want the Todos mini-app to fit into the existing app window, so that it feels like part of the PedryApps app rather than a separate system.
28. As a Mac user, I want the Todos mini-app to be accessible through normal app activation, including the existing global hotkey window activation behavior, so that I can get to my Todos quickly.
29. As a Mac user, I want the Todos mini-app to have predictable behavior when I add multiple Todos in sequence, so that rapid capture is reliable.
30. As a Mac user, I want the Todos mini-app to keep only active Todos, so that completed work does not accumulate as hidden history.
31. As a Mac user, I want Todo text to be stored exactly as I entered it, except for ignoring meaningless whitespace-only input, so that my wording is preserved.
32. As a Mac user, I want the Todos mini-app to avoid unnecessary features like reminders, tags, or nested lists in this initial version, so that the core capture-and-check-off flow stays simple.
33. As a Mac user, I want every Todo to carry a do-on date when it is created, so that I know which day I plan to work on it.
34. As a Mac user, I want the do-on date to default to today, so that adding a Todo stays a single-step action.
35. As a Mac user, I want to see each Todo's do-on date in its row, so that I can scan my list by day without opening anything.
36. As a Mac user, I want to change a Todo's do-on date without changing its text, so that I can reschedule it in place.
37. As a Mac user, I want the changed do-on date to persist across app restarts, so that my plan survives quitting the app.

## Implementation Decisions

- **Mini-app boundary**: Implement Todos as the Todos mini-app, following the global "Mini-app" language and the Todos glossary terms "Todo" and "Check off". Do not introduce "Task", "complete", "finish", or "archive" terminology in domain-facing behavior.
- **Primary seam: `TodosStore`**: Introduce a `TodosStore` as the main seam for the Todos mini-app. It owns the flat Todo list state, loading, saving, and mutations for add, check off, and reorder. The SwiftUI view should be thin over this interface.
- **Persistence seam reuse**: Reuse the existing `JSONDocumentStore` as the persistence seam. `TodosStore` depends on an injected `JSONDocumentStore` for a Todos document; no new lower-level persistence abstraction is introduced unless implementation proves necessary.
- **Document ownership**: The Todos mini-app owns its own Codable JSON document in Application Support (for example, a Todos-specific document file). This follows ADR 0002: one document per mini-app, independent schemas, no shared app-wide document.
- **Domain model shape**: Keep the domain model as plain Swift value types with no persistence annotations, per ADR 0002. Todo identity should be stable enough to support reorder and check-off operations without ambiguity.
- **Do-on date**: Every Todo has a required `Date` representing a day, with no time component. New Todos default to the start of the current local day. The store exposes a mutation for changing a Todo's do-on date, and every change persists.
- **Do-on date UI**: The add row includes a compact `DatePicker` defaulting to today; each list row shows a compact `DatePicker` bound to that Todo's do-on date for both display and editing.
- **Mutation serialization**: All Todos mutations go through the `TodosStore` on the main actor, consistent with ADR 0002's "no concurrent writers" consequence. The store is responsible for keeping in-memory state and persisted document consistent.
- **Check-off semantics**: "Check off" removes the Todo from the list permanently. There is no completed/archive state in this version.
- **List shape**: The Todos mini-app manages a single flat list. No projects, tags, reminders, priorities, subtasks, or nested structure.
- **Ordering**: The store maintains an explicit list order. New-Todo insertion position should be predictable and covered by tests; reorder operations persist the resulting order. The do-on date is display metadata and never changes list order.
- **Existing data**: The saved Todos document from initial testing is discarded. No decode fallback or schema version is added for documents without a do-on date; genuinely malformed documents still surface the existing load error.
- **Validation**: Adding a Todo rejects empty or whitespace-only text. The UI should not create a Todo in that case.
- **UI integration**: The Todos mini-app is presented in the existing macOS app window. Existing app-level window activation/global hotkey behavior remains the entry mechanism; this spec does not redesign app shell behavior beyond hosting the Todos mini-app.
- **Error handling**: Missing document on load yields an empty list. Save/load failures should be surfaced in a minimal, non-corrupting way; the store must not silently corrupt in-memory state.

## Testing Decisions

- **Good test definition**: Tests should verify external behavior through public interfaces, not implementation details. They should assert observable outcomes such as returned/loaded state, persisted document contents through the store seam, ordering, and removal behavior.
- **Primary module to test**: `TodosStore` is the primary unit-test seam. Tests should cover load, add, reject-empty, check-off removal, reorder, do-on date creation default and editing persistence, and persistence across store instances using a temporary directory/injected document store.
- **Persistence seam tests**: Reuse existing `JSONDocumentStore` tests as prior art for atomic save/load behavior. Add Todos-specific persistence tests only where Todos document behavior needs coverage.
- **UI tests**: Add lightweight UI/view-model-level tests only where SwiftUI behavior is not adequately covered by store tests; prefer store tests for business behavior. If UI tests are added, they should verify user-visible behaviors like add/check-off/reorder/empty state.
- **Prior art**: Follow the existing `JSONDocumentStoreTests` style in the test target: Swift Testing, `@MainActor` where needed, temporary directories, and behavior-focused assertions.
- **Verification commands**: After implementation, run the project verification commands from `AGENTS.md`: `xcodebuild -scheme PedryApps -destination 'platform=macOS' -configuration Debug build` and `xcodebuild test -scheme PedryApps -destination 'platform=macOS'`.

## Out of Scope

- Editing existing Todo text.
- Reminders, notifications, calendar integration, time-of-day or repeating scheduling. A do-on date is a plain day with no time, alert, or recurrence.
- Tags, projects, lists, subtasks, nesting, or grouping.
- Completed/history/archive views; checked-off Todos are removed permanently.
- Sync, iCloud, CloudKit, multi-device, or multi-user support.
- App Store/sandbox/notarization/distribution concerns beyond existing personal local-use scope.
- Menu bar extra, command palette, or new global hotkey behavior beyond the existing window activation.
- Search, filtering, bulk actions, or undo/redo.
- Cross-mini-app data model or shared persistence schema.

## Further Notes

- This spec follows the decisions in ADR 0001 (native Swift/SwiftUI, macOS-only, no third-party UI framework) and ADR 0002 (one Codable JSON document per mini-app in Application Support, plain Swift value types, main-actor mutations).
- Domain vocabulary follows `docs/GLOSSARY.md` and `docs/mini-apps/todos/GLOSSARY.md`: use "Todos mini-app", "Todo", "Check off", and "Do-on date"; avoid "Task", "complete", "finish", "archive", "due date", and "scheduled date".
- The existing codebase has only the app shell, `JSONDocumentStore`, and its tests; the Todos mini-app behavior described here is not yet implemented. A prior commit established Todos glossary/ADR direction but no Todos domain/store/UI implementation.
