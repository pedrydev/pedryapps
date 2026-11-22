# 01: Show and add Todos

**What to build:** A usable Todos mini-app in the existing PedryApps app window. The user can open the app, see the Todos mini-app with an empty state when no Todos exist, add a Todo with visible text, and have that Todo appear in a predictable position in a single flat list. Adding rejects empty or whitespace-only input. Todos load when the Todos mini-app appears and persist in the Todos mini-app's own local document so they remain after quitting and reopening the app.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] The Todos mini-app presents a single flat list of Todos in the existing app window, with a clear empty state when no Todos exist.
- [ ] A user can add a Todo with non-empty text; the Todo appears in a predictable position and its text is preserved as entered.
- [ ] Empty or whitespace-only input does not create a Todo.
- [ ] Todos are loaded through a `TodosStore` seam backed by the existing `JSONDocumentStore` using the Todos mini-app's own document; missing document loads as an empty list.
- [ ] Add/load behavior is persisted across app restart, and Todos mutations are serialized through the store on the main actor.
- [ ] Automated tests cover the external behavior of the Todos store for load, add, empty/whitespace rejection, and persistence across store instances; project verification commands pass.
