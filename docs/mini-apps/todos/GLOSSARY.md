# Todos

The Todos mini-app captures, categorizes, orders and checks off personal to-dos on a board. Back to [GLOSSARY-MAP.md](../../GLOSSARY-MAP.md).

## Language

**Board**:
The Todos mini-app's primary layout, which shows Categories side by side with each Category's Todos ordered inside it.
_Avoid_: Kanban, view

**Category**:
A user-defined group that owns Todos on the Board. Every Todo belongs to exactly one Category, and the Board may start empty but cannot be left empty once populated.
_Avoid_: Tag, column, lane, label, list

**Todo**:
A single item in a Category, captured to be checked off.
_Avoid_: Task, TODO item

**One-time Todo**:
A Todo with a point in time: a do-on date with a day and a start time.
_Avoid_: Dated Todo, point-in-time Todo

**Scheduled Todo**:
A Todo with a schedule because it is repetitive. Its model and UI are deferred.
_Avoid_: Recurring Todo, repeating Todo

**Check off**:
To mark a Todo as done, which removes it from its Category permanently.
_Avoid_: Complete, finish, archive

**Do-on date**:
The day and start time a one-time Todo is intended to be worked on. It is required when the Todo is created, defaults to 09:00 local time today or the next whole hour if that has passed, and can be changed later.
_Avoid_: Due date, deadline, scheduled date, reminder

**Due-check interval**:
The length of a due-check window, from 5 to 60 minutes. It defaults to 5 minutes and changes in steps of five.
_Avoid_: Check period, polling interval, refresh rate, reminder interval

**Due-check window**:
A range of local time ending at a boundary anchored to local midnight. A due-check interval sets its usual length.
_Avoid_: Review period, verified period, check range, lookback
