# Todos

The Todos mini-app captures, orders and checks off a single flat list of personal to-dos. Back to [GLOSSARY-MAP.md](../../GLOSSARY-MAP.md).

## Language

**Todo**:
A single item in the Todos mini-app's list, captured to be checked off.
_Avoid_: Task, TODO item

**One-time Todo**:
A Todo with a point in time: a do-on date with a day and a start time.
_Avoid_: Dated Todo, point-in-time Todo

**Scheduled Todo**:
A Todo with a schedule because it is repetitive. Its model and UI are deferred.
_Avoid_: Recurring Todo, repeating Todo

**Check off**:
To mark a todo as done, which removes it from the list permanently.
_Avoid_: Complete, finish, archive

**Do-on date**:
The day and start time a one-time Todo is intended to be worked on. It is required when the Todo is created, defaults to 09:00 local time today or the next whole hour if that has passed, and can be changed later.
_Avoid_: Due date, deadline, scheduled date, reminder

**Due-check interval**:
The elapsed time between checks for Do-on dates becoming due, also used as the lookback on launch. It defaults to 5 minutes.
_Avoid_: Check period, polling interval, refresh rate, reminder interval
