# MCP agent surface hosted in the app

To let AI agents act on the app, we expose a small MCP tool surface from the running app over Streamable HTTP on `127.0.0.1` at a user-configurable port, using the official Swift MCP SDK, instead of launching a separate stdio server that talks to the app over XPC. The app is already a persistent menu-bar process, so hosting the server in-process avoids a second executable target, an IPC boundary, and a pending-message queue; stdio and App Intents were rejected because they serve different clients and would duplicate the notification action.

## Consequences

- Agent tool calls fail with a connection error when the app is not running; there is no queue.
- Local exposure relies on loopback binding and `Origin` validation, with no authentication token.
- App Intents are deliberately out of scope; the notification action is exposed only as an MCP tool.
