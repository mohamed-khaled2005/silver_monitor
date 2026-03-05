import 'package:flutter/material.dart';

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;

  const SlideAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.begin = const Offset(0, 0.5),
  }) : super(key: key);

  @override
  _SlideAnimationState createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
