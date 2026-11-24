# Category Board replaces flat Todos list

The Todos mini-app originally had one flat ordered list. We replace it with a Board of user-defined Categories: every Todo belongs to exactly one Category, ordering lives within each Category, and Categories are managed in a separate panel. Columns were chosen over tags or filters because organization should be visible at a glance, accepting the loss of a single global order; existing Todos data is discarded per ADR 0003.

## Consequences

- The Board can start with no Categories, but once populated it cannot be left with none.
- Search and the menu bar overview remain global; the overview sorts by do-on date and uses Board order only to break ties.
- Replacing the flat list breaks stored Todos data, so this change starts with a clean document.
