import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeHint {
  static Future<bool> _seen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> _markSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  /// Spotlight coach-mark (مرة واحدة):
  /// - طبقة واحدة تعتيم (خفيفة)
  /// - فتحة حول الـ target
  /// - pulse ring
  /// - فقاعة شرح
  static Future<void> showSpotlightHint({
    required BuildContext context,
    required GlobalKey targetKey,
    required String prefsKey,
    required String message,

    /// شفافية الخلفية السوداء (خفيفة)
    double overlayOpacity = 0.35,

    /// توسعة الفتحة حول الزر
    double holePadding = 10,

    /// Radius للفتحة
    double holeRadius = 16,

    /// غلق تلقائي
    Duration autoDismiss = const Duration(seconds: 10),
  }) async {
    if (await _seen(prefsKey)) return;
    if (!context.mounted) return;

    // استنى بعد أول رسم
    await Future.delayed(const Duration(milliseconds: 350));
    if (!context.mounted) return;

    final targetContext = targetKey.currentContext;
    if (targetContext == null) return;

    final box = targetContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);

    bool removed = false;
    late final OverlayEntry entry;

    Future<void> dismiss() async {
      if (removed) return;
      removed = true;
      try {
        entry.remove();
      } catch (_) {}
      await _markSeen(prefsKey);
    }

    entry = OverlayEntry(
      builder: (_) {
        return _SpotlightHintOverlay(
          targetRect: rect,
          message: message,
          overlayOpacity: overlayOpacity,
          holePadding: holePadding,
          holeRadius: holeRadius,
          onDismiss: dismiss,
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(autoDismiss, () {
      if (context.mounted) dismiss();
    });
  }
}

class _SpotlightHintOverlay extends StatefulWidget {
  const _SpotlightHintOverlay({
    required this.targetRect,
    required this.message,
    required this.overlayOpacity,
    required this.holePadding,
    required this.holeRadius,
    required this.onDismiss,
  });

  final Rect targetRect;
  final String message;
  final double overlayOpacity;
  final double holePadding;
  final double holeRadius;
  final Future<void> Function() onDismiss;

  @override
  State<_SpotlightHintOverlay> createState() => _SpotlightHintOverlayState();
}

class _SpotlightHintOverlayState extends State<_SpotlightHintOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat();

  late final AnimationController _appear =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320))
        ..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _appear.dispose();
    super.dispose();
  }

  Rect _holeRect(Rect target, Size screen) {
    final inflated = target.inflate(widget.holePadding);

    final left = inflated.left.clamp(6.0, screen.width - 6);
    final top = inflated.top.clamp(6.0, screen.height - 6);
    final right = inflated.right.clamp(6.0, screen.width - 6);
    final bottom = inflated.bottom.clamp(6.0, screen.height - 6);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, c) {
          final screen = Size(c.maxWidth, c.maxHeight);
          final hole = _holeRect(widget.targetRect, screen);

          // Bubble layout
          final bubbleW = c.maxWidth < 360 ? 255.0 : 295.0;
          final aboveY = hole.top - 80;
          final placeAbove = aboveY > 24;

          final bubbleTop = placeAbove ? aboveY : (hole.bottom + 14);
          final bubbleLeft =
              (hole.center.dx - bubbleW / 2).clamp(12.0, c.maxWidth - bubbleW - 12);

          final arrowUp = !placeAbove;

          final fade = CurvedAnimation(parent: _appear, curve: Curves.easeOut);
          final scale = CurvedAnimation(parent: _appear, curve: Curves.easeOutBack);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onDismiss(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _SpotlightPainter(
                          target: hole,
                          t: _pulse.value,
                          overlayColor: Colors.black.withOpacity(widget.overlayOpacity),
                          primary: cs.primary,
                          radius: widget.holeRadius,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: bubbleTop,
                  left: bubbleLeft,
                  width: bubbleW,
                  child: FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(
                      scale: scale,
                      child: _HintBubble(
                        message: widget.message,
                        onClose: () => widget.onDismiss(),
                        arrowUp: arrowUp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.target,
    required this.t,
    required this.overlayColor,
    required this.primary,
    required this.radius,
  });

  final Rect target;
  final double t; // 0..1
  final Color overlayColor;
  final Color primary;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;

    final rrect = RRect.fromRectAndRadius(target, Radius.circular(radius));

    // ✅ طبقة واحدة: Overlay مع Hole (even-odd)
    final path = Path()
      ..addRect(full)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = overlayColor);

    // Pulse ring
    final pulseGrow = 8.0 + 10.0 * t;
    final alpha = (0.55 - 0.55 * t).clamp(0.0, 0.55);

    final pulseRect = target.inflate(pulseGrow);
    final pulseRRect = RRect.fromRectAndRadius(
      pulseRect,
      Radius.circular(radius + 8),
    );

    canvas.drawRRect(
      pulseRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withOpacity(alpha),
    );

    // Inner focus ring
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = primary.withOpacity(0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.target != target ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.primary != primary ||
        oldDelegate.radius != radius;
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({
    required this.message,
    required this.onClose,
    required this.arrowUp,
  });

  final String message;
  final VoidCallback onClose;
  final bool arrowUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrowUp)
            CustomPaint(
              size: const Size(18, 9),
              painter: _ArrowPainter(color: Colors.white, up: true),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.info_outline_rounded, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: cs.primary),
                  constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (!arrowUp)
            CustomPaint(
              size: const Size(18, 9),
              painter: _ArrowPainter(color: Colors.white, up: false),
            ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool up;
  _ArrowPainter({required this.color, required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path();

    if (up) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }

    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => false;
}
