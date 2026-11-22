# 03: Reorder Todos

**What to build:** A user can reorder Todos in the Todos mini-app's single flat list to reflect current priority. Reordering preserves each Todo's identity and text, updates the UI immediately, and persists the new order across app restart.

**Blocked by:** 01: Show and add Todos.

**Status:** ready-for-agent

- [ ] A user can reorder Todos in the single flat list through the Todos mini-app UI.
- [ ] Reordering preserves every Todo's identity and text; no Todos are duplicated or lost.
- [ ] The new order is visible immediately in the UI and persists across app restart.
- [ ] Automated tests cover reorder behavior and persistence through the `TodosStore` seam; project verification commands pass.
