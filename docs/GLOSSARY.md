# PedryApps

A macOS app for everyday utilities. Its major feature areas are called mini-apps. Terms specific to a mini-app live in that mini-app's glossary; see [GLOSSARY-MAP.md](./GLOSSARY-MAP.md).

## Language

**Mini-app**:
A major, self-contained feature area hosted by the app, such as Todos or Notifications.
_Avoid_: Feature, module, plugin

**Todos mini-app**:
The mini-app for capturing, categorizing, ordering and checking off personal to-dos on a board, each with a day it is intended to be worked on.
_Avoid_: TODO feature, Task manager

**Notifications mini-app**:
The mini-app for collecting in-app messages posted by mini-apps and showing their unread count in the menu bar.
_Avoid_: Notification center, Alerts feature

**AI agent**:
An external program acting on the user's behalf that calls actions the app exposes over MCP.
_Avoid_: Bot, automation, script

**Agent surface**:
The part of the app through which an AI agent calls app actions.
_Avoid_: MCP server, agent integration

**Probed component**:
A mini-app or the agent surface whose probes are reported in the diagnostics panel.
_Avoid_: Service, target, monitored component

**Probe**:
A check that reports whether a probed component has started (startup), remains operational (liveness), and can be used (readiness).
_Avoid_: Health check, heartbeat

**Probe result**:
The outcome of one probe: `success`, `failure`, or `unknown`.
_Avoid_: Health status, probe state

**Health state**:
A probed component's overall condition, derived from its probe results: `starting`, `healthy`, `degraded`, `unhealthy`, or `unknown`.
_Avoid_: Status, readiness state, service state

**Diagnostics panel**:
The app-level surface that shows each probed component's health state and probe results.
_Avoid_: Debug view, health dashboard
