import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:tp_router/tp_router.dart';
import '../routes/route.gr.dart';

class AuthRedirect extends TpRedirect<ProtectedRoute> {
  @override
  FutureOr<TpRouteData?> handle(BuildContext context, route) {
    // Check auth status (mock)
    const isAuthenticated = false;

    if (!isAuthenticated) {
      return const LoginRoute();
    }
  }
}
