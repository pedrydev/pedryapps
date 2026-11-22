# Persist the app's own model as a Codable JSON file in Application Support

The app owns its data model and may later map it to other apps or APIs, runs on one Mac for one user, and has no sync, querying, or multi-process requirement. We persist a single JSON document in `Application Support` via `Codable`, written atomically with a temporary file plus rename. SwiftData/Core Data were rejected because they couple the model to a framework and add migration machinery before there is a schema worth migrating; SQLite/GRDB were rejected because there are no queries to optimise at this scale. Reassess when data volume or concurrency makes whole-file rewrites costly.

## Consequences

- The domain model stays plain Swift value types with no persistence annotations.
- No concurrent writers: all mutations go through one store object on the main actor.
- No iCloud/CloudKit sync; a single-device local store is the scope.
