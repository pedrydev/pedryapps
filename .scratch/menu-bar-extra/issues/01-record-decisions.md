# 01: Record decisions

**What to build:** The repository documents the agreed model before any code changes, so later tickets can follow a single source of truth.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] One ADR records the menu presentation style, the single shared Todos store instance, no login item, the names "one-time Todo" and "scheduled Todo", the rule that checking off a scheduled Todo must not delete its series, and the breaking-change data rule.
- [ ] The breaking-change rule in the ADR says existing data is deleted during the code change, not by cleanup code in the app, and stays in force until explicitly reversed.
- [ ] The Todos glossary defines one-time Todo and scheduled Todo, and corrects the do-on date entry so it covers a day and a time instead of a date-only day.
- [ ] The earlier Todos spec is corrected where it says the do-on date has no time and never influences ordering; the new spec remains the source of truth for this feature.
- [ ] No implementation code is changed.
