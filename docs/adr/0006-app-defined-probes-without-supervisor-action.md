# App-defined probes without supervisor action

We report Kubernetes-style startup, liveness, and readiness probes for each mini-app and the agent surface, but the app only displays the results; it never restarts, disables, or hides a component. macOS has no supervisor-initiated health query, and a launchd/XPC helper would add a target and login-item behavior that ADR 0003 and ADR 0005 deliberately avoided, so probes are evaluated in-process over state the app already owns.

## Considered Options

- **launchd/XPC helper with restart policy**: rejected because launchd acts on process exit, not application state, and the helper would introduce a supervised process and a new target.
- **App-defined HTTP health endpoint**: rejected because nothing in macOS polls it or acts on its result.
- **No probes**: rejected because per-probed-component state needs to be visible.

## Consequences

- Liveness is derived from recorded errors and check timeouts, so it cannot detect a hung main thread.
- Notifications persistence errors and agent-surface listener state must be exposed for their probes to mean anything.
- Thresholds and results are diagnostics only; recovery stays a manual action.
