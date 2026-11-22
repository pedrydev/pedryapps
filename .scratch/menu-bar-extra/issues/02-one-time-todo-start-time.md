# 02: One-time Todo start time

**What to build:** I can give a one-time Todo a start time, see and change that time in the app, and trust that a Todo I cannot still start today is rejected and that this breaking change starts with a clean list.

**Blocked by:** 01: Record decisions.

**Status:** ready-for-agent

- [ ] A new Todo's do-on date defaults to 09:00 local time today, or to the next whole hour when 09:00 has already passed.
- [ ] The add control and each Todo row show and edit the day and time together.
- [ ] A start moment earlier than now is rejected on create and on change, with the existing whitespace-only validation still applying.
- [ ] The chosen day and time persist across app restarts, and the app and menu read the same value.
- [ ] The existing Todos data document is removed as part of this change so the new version starts with an empty list; no schema version, migration, or in-app cleanup code is added.
- [ ] Tests cover the 09:00 default, editing a time, persistence of the time, rejection of past start moments, and encoding of the time component.
- [ ] Build, test and lint commands from `AGENTS.md` pass.

## Comments

- Implemented on 2026-11-21.
- Existing Todos document was removed during implementation; it contained an empty list.
