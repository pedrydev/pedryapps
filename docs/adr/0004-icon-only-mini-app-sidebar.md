# Icon-only mini-app sidebar in the main window

The main window currently shows only Todos, but the app is meant to host more mini-apps. We replace the single-view content with a left sidebar that shows one icon per mini-app (Todos, Notifications), remember the last selected mini-app with Todos as the first-launch default, and keep macOS Settings as a separate window. The sidebar is icon-only with tooltips and accessibility labels derived from the mini-app name, because it mirrors the menu bar's compact visual language and avoids a second navigation vocabulary; Todos becomes a destination rather than the whole window.

## Consequences

- Adding a mini-app means adding a sidebar icon and destination, not a second main window.
- Settings remains outside the sidebar, so mini-app settings do not need a sidebar entry.
