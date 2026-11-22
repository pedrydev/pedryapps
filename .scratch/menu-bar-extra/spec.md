Status: ready-for-agent

# Menu Bar Extra Spec

## Problem Statement

I want a small overview of the most important information available from the top bar of my Mac, without opening PedryApps or switching away from what I am doing. As more mini-apps are added, that overview should be able to grow. Right now the only information worth surfacing is the Todos I plan to start today, with enough detail to decide which one to work on next. I also want a couple of small actions in the same place so I can act without opening the app.

## Solution

Add a menu bar extra to PedryApps: a small status-bar icon that opens a compact menu. The menu shows a "Today" overview containing the first five one-time Todos whose do-on date is today and whose start moment has not passed. Each Todo is shown with its title and the time left before that moment, ordered by the shortest time left first. An action opens the main app window, and each row has a Check off action. The overview is reserved for future mini-apps, but this change implements only the Todos contribution.

## User Stories

1. As a Mac user, I want a PedryApps icon in the top bar, so that I can reach a small overview without opening the app.
2. As a Mac user, I want the icon to use a plain template image, so that it follows the system menu bar appearance.
3. As a Mac user, I want the icon to stay visually simple, so that it does not compete with other menu bar items.
4. As a Mac user, I want clicking the icon to open a menu, so that the overview is one click away.
5. As a Mac user, I want the menu to be a dropdown rather than a floating panel, so that it does not create another window to manage.
6. As a Mac user, I want the menu to open promptly, so that checking the overview is quick.
7. As a Mac user, I want the menu to show a "Today" header with a count, so that I know how many Todos are in the overview.
8. As a Mac user, I want the count to include only Todos I can still start today, so that it matches the rows I see.
9. As a Mac user, I want to see at most five Todos, so that the overview stays short.
10. As a Mac user, I want the Todos ordered by the time left before their start moment, so that the next one to start is first.
11. As a Mac user, I want Todos with the same start moment to keep their existing order, so that equal cases stay predictable.
12. As a Mac user, I want each row to show the Todo text, so that I can recognise the item.
13. As a Mac user, I want each row to show the time left before its start moment, so that I can judge urgency.
14. As a Mac user, I want the time left to be compact, so that it fits in a menu row.
15. As a Mac user, I want a row reading "now" when less than a minute remains, so that I do not see a confusing fraction.
16. As a Mac user, I want a trailing line telling me how many more Todos remain today, so that the five-row limit is not misleading.
17. As a Mac user, I want that trailing line to count only Todos I can still start today, so that it agrees with the header.
18. As a Mac user, I want Todos whose start moment has passed to be absent from the menu, so that I only see what I can still start.
19. As a Mac user, I want passed Todos to stay in the main Todos list, so that hiding them in the menu does not delete them.
20. As a Mac user, I want a Todo to disappear from an open menu when its start moment passes, so that the overview stays correct.
21. As a Mac user, I want the menu to refresh its time labels while it is open, so that the countdown does not freeze.
22. As a Mac user, I want "today" to mean the current local calendar day, so that the overview matches the day I am in.
23. As a Mac user, I want an empty overview to say "Nothing upcoming today", so that I know why no rows are shown.
24. As a Mac user, I want an action in the menu that opens PedryApps, so that I can reach the full app from the overview.
25. As a Mac user, I want the global hotkey to keep working whether or not the main window has appeared, so that both entry points are reliable.
26. As a Mac user, I want a Check off action on each row, so that I can finish a Todo from the overview.
27. As a Mac user, I want checking off from the menu to behave exactly like checking off in the app, so that the result is consistent.
28. As a Mac user, I want the menu to update after I check off a Todo, so that the list and counts are correct immediately.
29. As a Mac user, I want every Todo to have a start time as well as a do-on date, so that "time left" has a precise meaning.
30. As a Mac user, I want the start time to default to 09:00 local time on the chosen day, so that adding a Todo stays a single-step action.
31. As a Mac user, I want to set the time on the do-on date when I add a Todo, so that I can plan a specific start.
32. As a Mac user, I want to change the time on a Todo's do-on date later, so that I can reschedule a start in place.
33. As a Mac user, I want the app and the menu to show the same do-on date, so that the two views agree.
34. As a Mac user, I want a start time in the past to be rejected, so that a new Todo does not vanish from the overview immediately.
35. As a Mac user, I want the changed do-on date to persist across app restarts, so that my plan survives quitting the app.
36. As a Mac user, I want checking off from the menu to persist, so that the Todo does not come back after restart.
37. As a Mac user, I want the menu to share the app's current Todos state, so that it never shows a stale copy of the list.
38. As a Mac user, I want adding a mini-app later not to require redesigning the status bar, so that the overview can grow.
39. As a Mac user, I want no login-item registration, so that the app keeps its current manually launched behavior.
40. As a Mac user, I want the existing main Todos list to keep its manual order, so that the overview does not change how I organise the app.
41. As a developer, I want the overview selection to be a pure function of Todos, a calendar and the current time, so that it is easy to test.
42. As a developer, I want the app to start with an empty Todos list after this breaking model change, so that no old date-only data is read as a start time.

## Implementation Decisions

- **Scene shape**: Add one menu bar extra scene alongside the existing window scene. Use the menu presentation style, not a window style. The status item uses a static template symbol with no count badge.
- **Shared state**: The app creates one Todos store instance and passes the same instance to both scenes. No singleton, environment injection, or store refactor.
- **Hotkey lifetime**: Register the existing global hotkey once when the app is created, instead of from the window's appearance callback.
- **Overview scope**: The menu is an app-level host for future mini-apps. This change contributes only the Todos section; no plugin mechanism or cross-mini-app abstraction is introduced.
- **Do-on date shape**: The do-on date carries a day and a time. The name "Do-on date" and the existing glossary term are kept. New Todos default to 09:00 local time today, or to the next whole hour when 09:00 has already passed; existing stored values are not upgraded.
- **Editors**: The add row and each Todo row edit the day and the time together in one control. A start moment earlier than now is rejected on create and on change.
- **Selection rule**: From all Todos, keep those whose do-on date is the current local day and whose start moment is in the future. Order them by increasing time left, using their existing manual order only when start moments are equal. Take the first five.
- **Time left**: Compute from the current time to the start moment. Show whole minutes in a compact form; show "now" when less than one minute remains.
- **Refresh**: Recompute the selection when the menu content is produced; refresh at least every minute and remove a row promptly at its start moment so labels and membership stay current.
- **Actions**: The menu offers "Open PedryApps" and a Check off action per row. Check off calls the existing store mutation. No add, edit, search, or settings controls in the menu.
- **Main list**: The main Todos list stays manually ordered. The overview's time-based order does not change it.
- **Vocabulary**: Use one-time Todo for a Todo with a point in time, and scheduled Todo for the future repetitive kind. Keep Todo, Check off, and Do-on date as the domain terms.
- **Documentation**: Record one ADR covering the menu presentation style, the single shared store instance, no login item, the two Todo kinds' names, the future rule that checking off a scheduled Todo must not delete its series, and the breaking-change data rule. Correct the Todos glossary and the earlier Todos spec where they describe a date-only do-on date, no time, and no date-based ordering.
- **Breaking-change data rule**: On every breaking change to a data model, existing data is deleted during the code change, not by cleanup code in the app. This rule stays in force until explicitly reversed. For this change, the existing Todos document is removed as part of the work; the app gains no schema version and no migration path.
- **Error handling**: Missing document still yields an empty list. Save and load failures remain surfaced through the existing store error path; the menu does not add a separate error state.

## Testing Decisions

- **Good test definition**: Test external behavior through public seams. Assert returned selections, ordering, counts, validation outcomes and persisted state; do not assert view internals, timer implementation or private helpers.
- **Primary new seam**: One pure Domain query that takes Todos, a calendar and a "now" value and returns the overview selection. Test day filtering, exclusion of passed start moments, ordering by time left, the equal-time tie-break, and the five-row limit.
- **Existing seams reused**: Test create and change validation through `TodosStore`, including rejection of past start moments and persistence of an accepted time. Extend do-on date encoding tests for the time component. Reuse document-store tests as prior art; no new persistence abstraction or cleanup test.
- **No UI test seam**: Do not add a view model or SwiftUI test seam for the menu. The menu view is a thin rendering of the pure query and the store.
- **Prior art**: Follow the Swift Testing style in the existing test target: `@MainActor` for store tests, temporary directories for injected persistence, and behavior-focused assertions.
- **Verification commands**: Run the build, test and lint commands from `AGENTS.md` after implementation.

## Out of Scope

- The scheduled Todo model, recurrence rules, next-occurrence calculation, and its UI.
- Checking off an occurrence of a scheduled Todo; the ADR records the constraint only.
- Adding, editing or reordering Todos from the menu.
- A badge or count on the status icon, or a different icon per state.
- Login-item registration, Dock hiding, or other app-lifecycle changes.
- Menu bar extras on platforms other than macOS.
- Notifications, calendar integration, sync, or a settings screen.
- Changes to the main Todos list order or to check-off semantics outside the menu.
- Runtime data migration, schema versioning, or a deletion mechanism inside the app.
- Search, filtering, bulk actions, or undo/redo in the menu.
- Contributions from other mini-apps to the overview.

## Further Notes

- The earlier decision to rank by "time left before the do-on date" is now concrete: the do-on date has a start time, and the ranking is by the time from now to that moment. Dates in the past are excluded, not ranked.
- The manual order of the Todos list is only a tie-break in the overview; it is not the overview's primary ordering.
- Domain vocabulary follows `docs/GLOSSARY.md` and `docs/mini-apps/todos/GLOSSARY.md`. Avoid due date, deadline, reminder, task, complete, finish and archive.
- This spec follows ADR 0001 for a native SwiftUI app on macOS only and ADR 0002 for one Codable JSON document per mini-app with main-actor mutations.
