import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

class LocationDisplay extends StatefulWidget {
  final Widget child;
  final double bottom;
  final TpNavKey? navigatorKey;

  const LocationDisplay({
    super.key,
    required this.child,
    this.bottom = 0,
    this.navigatorKey,
  });

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  @override
  void initState() {
    super.initState();
    TpRouter.instance.goRouter.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    TpRouter.instance.goRouter.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.bottom,
          child: IgnorePointer(
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: SafeArea(
                top: false,
                child: Text(
                  'Start: ${TpRouter.instance.location(navigatorKey: widget.navigatorKey).fullPath}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
