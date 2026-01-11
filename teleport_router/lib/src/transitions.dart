import 'package:flutter/cupertino.dart';
import 'package:teleport_router_annotation/teleport_router_annotation.dart';

/// A fade transition that fades the page in/out.
class TeleportFadeTransition extends TeleportTransitionsBuilder {
  const TeleportFadeTransition();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// A slide transition that slides the page from the right.
class TeleportSlideTransition extends TeleportTransitionsBuilder {
  const TeleportSlideTransition();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutQuart,
      reverseCurve: Curves.easeInOutQuint,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    );
  }
}

/// A page transition that uses the Cupertino style.
class TeleportCupertinoPageTransition extends TeleportTransitionsBuilder {
  const TeleportCupertinoPageTransition();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  }
}

/// A slide transition that slides the page from the bottom.
class TeleportSlideUpTransition extends TeleportTransitionsBuilder {
  const TeleportSlideUpTransition();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutQuart,
      reverseCurve: Curves.easeInOutQuint,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    );
  }
}

/// A scale transition that scales the page in/out.
class TeleportScaleTransition extends TeleportTransitionsBuilder {
  const TeleportScaleTransition();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutQuart,
      reverseCurve: Curves.easeOutBack,
    );
    return ScaleTransition(
      scale: curvedAnimation,
      child: child,
    );
  }
}

/// No transition - page appears instantly.
class TeleportNoTransition extends TeleportTransitionsBuilder {
  const TeleportNoTransition();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
