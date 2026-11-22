# 02: Check off Todos

**What to build:** A user can check off a Todo from the Todos mini-app list. Checking off removes the Todo permanently from the single flat list, with no completed or archived history. The UI updates immediately and the removal persists across app restart.

**Blocked by:** 01: Show and add Todos.

**Status:** ready-for-agent

- [ ] A user can check off a visible Todo in the Todos mini-app.
- [ ] Checking off removes that Todo permanently from the list; no completed, archived, or hidden history is kept.
- [ ] The check-off result is visible immediately in the UI and persists across app restart.
- [ ] Automated tests cover check-off removal and persistence through the `TodosStore` seam; project verification commands pass.
