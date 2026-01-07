import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:tp_router/tp_router.dart';
import '../routes/route.gr.dart';

FutureOr<TpRouteData?> authRedirect(BuildContext context, TpRouteData state) {
  // Check auth status (mock)
  const isAuthenticated = false;

  if (!isAuthenticated) {
    return const LoginRoute();
  }
}
