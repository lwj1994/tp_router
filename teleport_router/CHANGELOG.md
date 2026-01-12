## 0.8.0
* **API Break**: Renamed `initialLocation` to `initialRoute` in `TeleportRouter` constructor.
* **API Break**: Renamed `currentRoute` (getter on context/key) to return `TeleportRouteData` and updated internal naming consistency.
* **Feature**: Added comprehensive logging system for navigation events. Enable via `enableLogging` in `TeleportRouter`.
* **Feature**: Added `popUntil`, `popToInitial`, and `popTo` for more fine-grained navigation control.
* **Docs**: Refined internal documentation and comments for better clarity.

## 0.7.2
* **Docs**: Updated documentation to explain the "Teleport" name origin and refine navigation examples.
* **Sync**: Updated all related packages to 0.7.2 for consistency.

## 0.7.1
* **Fix**: Resolved dependency conflicts in example projects when using path overrides.
* **Sync**: Updated all related packages to 0.7.1 for consistency.

## 0.7.0
* **Rename**: Successfully renamed `tp_router` to `teleport_router`. This is a major rebranding to provide a more descriptive and memorable name.
* **Refactor**: All `tp_` prefixes in classes, methods, and variables have been updated to `teleport_` or `Teleport`.
* **Migration**: Existing users should update their imports from `package:tp_router/...` to `package:teleport_router/...`.

