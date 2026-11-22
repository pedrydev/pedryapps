# Native Swift + SwiftUI with no cross-platform abstraction

The app targets macOS only, its UI is list/form/dashboard-shaped, and there is no requirement to reuse the codebase elsewhere. We use Swift 6 and SwiftUI in a single Xcode app target, dropping to AppKit only where SwiftUI lacks a primitive. Electron, Tauri, MAUI, React Native macOS, and Flutter were rejected: each adds a bridge to the OS (native modules, platform channels, custom handlers) that this app does not need, and their main benefit — cross-platform reuse — is explicitly out of scope. The Swift learning curve is accepted as the cost of fitness, not as a goal in itself.

## Consequences

- Global hotkey and any future menu bar extra are AppKit-facing work, not a reason to change stacks.
- No third-party UI framework; SPM is the dependency manager if a dependency is ever justified.
