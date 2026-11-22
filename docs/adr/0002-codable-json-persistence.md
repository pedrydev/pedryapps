# Persist each mini-app's model as its own Codable JSON file in Application Support

The app is a container of independent mini-apps, each owning its data model, and runs on one Mac for one user with no sync, querying, or multi-process requirement. Each mini-app persists one JSON document in `Application Support` (for example `todos.json`) via `Codable`, written atomically with a temporary file plus rename. One document per mini-app keeps each schema independent as mini-apps are added; a single app-wide document was rejected because it would couple unrelated mini-apps into one Codable graph. SwiftData/Core Data were rejected because they couple the model to a framework and add migration machinery before there is a schema worth migrating; SQLite/GRDB were rejected because there are no queries to optimise at this scale. Reassess when data volume or concurrency makes whole-file rewrites costly.

## Consequences

- The domain model stays plain Swift value types with no persistence annotations.
- A mini-app owns its store and document; adding a mini-app adds a document rather than changing a shared schema.
- No concurrent writers: mutations for a mini-app go through its store object on the main actor.
- No iCloud/CloudKit sync; a single-device local store is the scope.
