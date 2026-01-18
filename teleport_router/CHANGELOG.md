# 0.8.2

* Significant refactoring of page building logic to fix "gray background" issue on Cupertino.
* Remove `CupertinoPage` and `MaterialPage` in favor of `CustomTransitionPage` for consistent behavior and better control.
* Use `TeleportCupertinoPageTransition` by default to preserve iOS aesthetics without the forced backdrop.
* Update `TeleportPageType` to only include `defaultType` and `swipeBack`.
