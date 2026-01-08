import 'package:flutter/material.dart';

/// A wrapper widget that allows closing the page by swiping from left to right.
///
/// This implements the "Swipe Back" gesture common on iOS.
/// By default, it detects gestures from the left edge.
/// Set [edgeWidth] to null or 0 to allow swiping from anywhere.
class SwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onClose;
  final double dragThreshold;

  /// The width of the edge area where the swipe gesture can start.
  /// Set to 0 or null to allow swiping from anywhere.
  final double? edgeWidth;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.onClose,
    this.dragThreshold = 80.0,
    this.edgeWidth = 40.0,
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isDragging = false;
  bool _isGestureAvailable = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _screenWidth => MediaQuery.of(context).size.width;

  void _handleDragStart(DragStartDetails details) {
    if (_isDragging || _controller.isAnimating) return;

    final edge = widget.edgeWidth ?? 0;
    if (edge <= 0) {
      _isGestureAvailable = true;
    } else {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPos = renderBox.globalToLocal(details.globalPosition);
        _isGestureAvailable = localPos.dx <= edge;
      } else {
        _isGestureAvailable = false;
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isGestureAvailable && !_isDragging) return;

    final delta = details.primaryDelta ?? 0;
    if (!_isDragging && delta > 0) {
      _isDragging = true;
      _dragOffset = 0;
    }

    if (_isDragging) {
      setState(() {
        _dragOffset += delta;
        if (_dragOffset < 0) _dragOffset = 0;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) {
      _isGestureAvailable = false;
      return;
    }

    final velocity = details.primaryVelocity ?? 0;

    // Swipe fast or drag far enough
    if (_dragOffset > widget.dragThreshold || velocity > 400) {
      _close();
    } else {
      _cancel();
    }

    _isGestureAvailable = false;
  }

  void _close() {
    _isDragging = false;
    _controller.value = _dragOffset / _screenWidth;
    _controller.animateTo(1.0, curve: Curves.easeOut).then((_) {
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      }
    });
  }

  void _cancel() {
    _isDragging = false;
    _controller.value = _dragOffset / _screenWidth;
    _controller.animateTo(0.0, curve: Curves.easeOut).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      excludeFromSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final currentOffset =
              _isDragging ? _dragOffset : _controller.value * _screenWidth;

          return Transform.translate(
            offset: Offset(currentOffset, 0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  if (currentOffset > 0)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(-5, 0),
                    ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
