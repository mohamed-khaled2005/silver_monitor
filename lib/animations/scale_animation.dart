import 'package:flutter/material.dart';

class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const ScaleAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  _ScaleAnimationState createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
