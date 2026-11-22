# Menu bar extra overviews and clean starts for breaking model changes

The app needs an app-level surface whose content will grow as mini-apps are added, starting with today's one-time Todos. We add a menu-style menu bar extra with a static template icon, pass the single existing Todos store instance to both the window and the menu scene, and register no login item: a dropdown avoids a new window lifecycle, and one store avoids a second source of truth. A one-time Todo has a point in time; a scheduled Todo will have a schedule because it is repetitive, and checking off a scheduled Todo must affect an occurrence rather than delete the series. When a data model change breaks stored data, we delete the data during the code change instead of adding runtime migration, schema versioning or in-app cleanup; this is a single-user local app, and the user has chosen a clean start on every breaking change until told otherwise.

## Consequences

- The menu is an app-level host; adding a mini-app contributes content without changing the status bar itself.
- Future scheduled Todos need occurrence-level check-off; the current delete-on-check-off behavior applies only to one-time Todos.
- Every breaking model change discards existing data as part of the change, and that loss must be stated in the change's documentation.
