import 'package:flutter/material.dart';

/// Wraps a screen with a consistent fade + slide entrance animation.
class PageTransition extends StatefulWidget {
  final Widget child;
  final double delay;

  const PageTransition({super.key, required this.child, this.delay = 0});

  @override
  State<PageTransition> createState() => _PageTransitionState();
}

class _PageTransitionState extends State<PageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(position: _slideAnim, child: widget.child),
        );
      },
    );
  }
}

/// Staggered entrance animation for list items.
class StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration totalDuration;

  const StaggeredItem({
    super.key,
    required this.child,
    required this.index,
    this.totalDuration = const Duration(milliseconds: 600),
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.totalDuration);
    final delay = widget.index * 0.05;
    Future.delayed(Duration(milliseconds: (delay * 1000).round()), () {
      if (mounted) _ctrl.forward();
    });
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Opacity(
          opacity: _anim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _anim.value)),
            child: widget.child,
          ),
        );
      },
    );
  }
}
