# 03: Menu bar extra shell

**What to build:** I have a small PedryApps item in the top bar that opens a dropdown menu, can open the app, and does not break the existing hotkey or require the app to start at login.

**Blocked by:** 01: Record decisions.

**Status:** ready-for-agent

- [ ] A static template status-bar icon appears in the menu bar and opens a dropdown menu.
- [ ] The menu contains an "Open PedryApps" action that activates the app and brings the main window forward.
- [ ] The app creates one Todos store instance and passes the same instance to the window and the menu bar extra; no singleton, environment injection, or store refactor is introduced.
- [ ] The existing global hotkey is registered when the app is created and works whether or not the main window has appeared.
- [ ] No login item is registered, the icon carries no count badge, and the menu is not a floating window.
- [ ] Build, test and lint commands from `AGENTS.md` pass.
