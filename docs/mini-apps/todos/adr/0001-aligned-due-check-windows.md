# Aligned due-check windows

Due checks no longer follow elapsed minutes since launch; they review due-check windows whose boundaries are anchored to local midnight, so consecutive windows are never shorter than the due-check interval and never overlap or leave gaps. Resetting boundaries at each hour would overlap near the hour for intervals that do not divide 60 — with a 25-minute interval, checks run at 00:00, 00:25, 00:50, 01:15, 01:40, 02:05 and so on instead of 01:00 after 00:50 — so midnight anchoring wins even though the boundary times drift through the hour. At launch only the last fully completed window is reviewed as catch-up, never the partial one; the last reviewed boundary is persisted so a window is reviewed at most once across restarts, and changing the due-check interval reschedules from the current time. When the interval changes, the next window starts at the last reviewed boundary instead of one new interval before the boundary, so coverage stays gap-free even though that window can be longer than the new interval.

## Consequences

- For intervals of 25, 35, 40, 45, 50 and 55 minutes, check times are not the same minutes past every hour.
- A Todo whose Do-on date falls in a window is reviewed when that window ends, not when its own time passes.
- Restarting the app cannot replay a window that has already been reviewed.
