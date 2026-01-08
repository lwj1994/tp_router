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
