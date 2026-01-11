import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:teleport_router/teleport_router.dart';
import '../routes/route.gr.dart';

class AuthRedirect extends TeleportRedirect<ProtectedRoute> {
  @override
  FutureOr<TeleportRouteData?> handle(BuildContext context, route) {
    // Check auth status (mock)
    const isAuthenticated = false;

    if (!isAuthenticated) {
      return const LoginRoute();
    }
  }
}
