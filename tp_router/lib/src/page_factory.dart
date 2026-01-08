import 'package:flutter/widgets.dart';
import 'package:tp_router/src/route.dart';

/// Abstract base class for defining custom Page construction logic.
///
/// Implement this class to gain full control over the [Page] object created for a route.
/// This allows using [MaterialPage], [CupertinoPage], or custom [Page] implementations
/// (like a ModalBottomSheetPage) instead of the default [CustomTransitionPage].
///
/// Example:
/// ```dart
/// class MyMaterialPageFactory extends TpPageFactory {
///   const MyMaterialPageFactory();
///
///   @override
///   Page<dynamic> buildPage(BuildContext context, TpRouteData data, Widget child) {
///     return MaterialPage(
///       key: data.pageKey,
///       child: child,
///       name: data.routeName,
///       arguments: data.extra,
///     );
///   }
/// }
/// ```
abstract class TpPageFactory {
  const TpPageFactory();

  /// Build the [Page] for the route.
  ///
  /// [data] contains route parameters, extra data, and page Key.
  /// [child] is the widget built by the route's builder methods.
  Page<dynamic> buildPage(BuildContext context, TpRouteData data, Widget child);
}
