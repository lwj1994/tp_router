# tp_router_generator

Code generator for [tp_router](https://pub.dev/packages/tp_router).

## Overview

This package is responsible for generating the type-safe routing code used by `tp_router`. It processes classes annotated with `@TpRoute` and produces a corresponding `.g.dart` file containing route classes and wiring.

## Installation

Add `tp_router_generator` to your `dev_dependencies` along with `build_runner`:

```yaml
dev_dependencies:
  build_runner: any
  tp_router_generator: any
```

## Usage

Run the build runner to generate the code:

```bash
flutter pub run build_runner build
```

Or watch for changes:

```bash
flutter pub run build_runner watch
```

## Features

- Generates type-safe route classes (e.g., `HomeRoute`, `UserRoute`).
- Handles parameter extraction from path, query, and extra data.
- Supports custom transitions and global configuration.
- Supports shell routes (`TpShellRoute`, `TpStatefulShellRoute`).
