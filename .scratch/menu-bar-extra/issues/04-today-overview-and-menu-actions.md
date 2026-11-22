# 04: Today overview and menu actions

**What to build:** The menu shows the five one-time Todos I can still start today, with the time left before each start, and lets me check one off without opening the app.

**Blocked by:** 02: One-time Todo start time, 03: Menu bar extra shell.

**Status:** ready-for-agent

- [ ] A pure Domain selection returns Todos whose do-on date is the current local day and whose start moment is in the future, ordered by increasing time left with existing manual order as the tie-break, limited to five.
- [ ] The menu shows a "Today (N)" header whose count matches the rows shown, and a trailing "N more today" line when additional upcoming Todos exist.
- [ ] Each row shows the Todo text and a compact time-left label, using "now" when less than a minute remains.
- [ ] When no Todos are upcoming today, the menu shows "Nothing upcoming today".
- [ ] Todos whose start moment has passed are hidden from the menu only; they remain in the store and in the main Todos list, and counts exclude them.
- [ ] The selection and labels refresh on a one-minute cadence, including removal of a row when its start moment passes while the menu is open.
- [ ] Each row has a Check off action that uses the existing store mutation, persists, and updates the menu immediately.
- [ ] Tests cover day filtering, exclusion of passed start moments, time-left ordering, equal-time tie-break, the five-row limit, and formatting of the time-left label.
- [ ] Build, test and lint commands from `AGENTS.md` pass.
