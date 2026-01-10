## 0.6.2
*   **Version Bump**: Synchronize version with `tp_router` 0.6.2.

## 0.6.1
* **Refactor**: Major internal restructuring. Split monolithic generator logic into `RouteWriter` and `RouteData` models for better maintainability and extensibility.

## 0.6.0
* **Fix**: Removed redundant `TpRouteObserver` generation (now handled by `TpNavKey` logic).
* **Fix**: Cleaned up unused imports in generated code.
* **Refactor**: Use constant prefix for route names.

## 0.5.0

*   **Breaking Change**: No longer reads `branchIndex` from annotations. Branching logic now relies on `parentNavigatorKey` matching `branchKeys` definitions.
*   **Fix**: Ensure correct branch association for child routes in indexed stacks.

## 0.4.0

*   **Type-Safe NavKeys**: Updated generation logic to support `Type`-based navigator keys. Shell routes now instantiate NavKeys and reference their `key` property.
*   **Crash Fix**: Added null-aware access (`?.`) for extra parameter extraction to prevent crashes when `extra` is null at runtime.

## 0.3.0

*   **🔄 Support for Class-based Callbacks**: Updated generator to instantiate and use `TpRedirect` and `TpOnExit` classes.
*   **🛠️ Type Reconstruction**: Added generation of `static T fromData(TpRouteData)` for all route classes.
*   **🐚 Shell Route Optimization**: Stopped generating transition parameters for shell routes.
*   **💅 Formatting**: Improved generated code formatting and fixed various lint warnings in output.

## 0.1.1

* Added comprehensive dartdoc comments to all public APIs.
* Created example directory with minimal demonstration.
* Enhanced README with detailed usage instructions and troubleshooting.
* Added repository and issue_tracker metadata to pubspec.yaml.

## 0.1.0


* Simplified generated code for extra parameter extraction.
* Removed unnecessary type casts in generated builder functions.
* Improved code formatting and indentation.
* Auto-import complex parameter types.

## 0.0.1

* Initial release.
* Support for type-safe route generation with parameter extraction.
* Support for Function and Class based redirect configuration.
* Support for ShellRoute and StatefulShellRoute generation.
* Support for configurable output path via `build.yaml` options.
