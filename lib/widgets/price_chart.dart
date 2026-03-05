import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';

const Color _kSilverAccent = Color(0xFFCFD8DC);
const Color _kSilverAccentDark = Color(0xFF90A4AE);

class PriceChart extends StatefulWidget {
  const PriceChart({
    Key? key,
    required this.refreshTick,
  }) : super(key: key);

  final int refreshTick;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int? _selectedIndex;

  void _handleTouch({
    required Offset localPosition,
    required Size size,
    required int length,
  }) {
    if (length <= 0 || size.width <= 0) return;

    const horizontalPadding = 16.0;
    final usableWidth =
        (size.width - horizontalPadding * 2).clamp(1.0, size.width);
    var x = localPosition.dx;
    if (x < horizontalPadding) x = horizontalPadding;
    if (x > size.width - horizontalPadding) x = size.width - horizontalPadding;

    final step = length <= 1 ? usableWidth : usableWidth / (length - 1);
    final relative = x - horizontalPadding;
    final idx = (relative / step).round().clamp(0, length - 1);
    setState(() => _selectedIndex = idx);
  }

  List<DateTime> _buildDates({
    required int count,
    required DateTime? latest,
  }) {
    final end = (latest ?? DateTime.now()).toLocal();
    final base = DateTime(end.year, end.month, end.day);
    return List<DateTime>.generate(
      count,
      (i) => base.subtract(Duration(days: (count - 1) - i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoldProvider>();
    final prices = provider.weeklyOuncePrices;

    if (prices.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات للرسم البياني.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final dates = _buildDates(
      count: prices.length,
      latest: provider.currentGoldPrice?.lastUpdated,
    );

    final maxPrice = prices.reduce(math.max);
    final minPrice = prices.reduce(math.min);

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: (d) => _handleTouch(
            localPosition: d.localPosition,
            size: size,
            length: prices.length,
          ),
          onPanUpdate: (d) => _handleTouch(
            localPosition: d.localPosition,
            size: size,
            length: prices.length,
          ),
          onTapDown: (d) => _handleTouch(
            localPosition: d.localPosition,
            size: size,
            length: prices.length,
          ),
          onPanEnd: (_) => setState(() => _selectedIndex = null),
          onTapUp: (_) => setState(() => _selectedIndex = null),
          child: CustomPaint(
            size: size,
            painter: _SilverPriceChartPainter(
              prices: prices,
              dates: dates,
              maxPrice: maxPrice,
              minPrice: minPrice,
              selectedIndex: _selectedIndex,
            ),
          ),
        );
      },
    );
  }
}

class _SilverPriceChartPainter extends CustomPainter {
  _SilverPriceChartPainter({
    required this.prices,
    required this.dates,
    required this.maxPrice,
    required this.minPrice,
    required this.selectedIndex,
  });

  final List<double> prices;
  final List<DateTime> dates;
  final double maxPrice;
  final double minPrice;
  final int? selectedIndex;

  static const EdgeInsets chartPadding = EdgeInsets.fromLTRB(16, 16, 16, 62);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final chartRect = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.horizontal,
      size.height - chartPadding.vertical,
    );
    if (chartRect.width <= 0 || chartRect.height <= 0) return;

    _drawBackground(canvas, chartRect);
    _drawGrid(canvas, chartRect);
    _drawMinMaxLabels(canvas, chartRect);
    _drawXAxisLabels(canvas, chartRect);

    final range = (maxPrice - minPrice) == 0 ? 1.0 : (maxPrice - minPrice);
    final points = <Offset>[];

    if (prices.length == 1) {
      final x = chartRect.center.dx;
      final y = _y(prices.first, chartRect, minPrice, range);
      points.add(Offset(x, y));
    } else {
      final xStep = chartRect.width / (prices.length - 1);
      for (var i = 0; i < prices.length; i++) {
        points.add(
          Offset(
            chartRect.left + i * xStep,
            _y(prices[i], chartRect, minPrice, range),
          ),
        );
      }
    }

    final path = _smoothPath(points);
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          _kSilverAccent.withValues(alpha: 0.25),
          _kSilverAccent.withValues(alpha: 0.03),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = _kSilverAccentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = _kSilverAccent;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      _drawTooltip(
        canvas: canvas,
        point: points[selectedIndex!],
        price: prices[selectedIndex!],
        date: dates[selectedIndex!],
        rect: chartRect,
      );
    }
  }

  void _drawBackground(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          AppColors.cardDark,
          AppColors.cardLight.withValues(alpha: 0.9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;

    const horizontalLines = 4;
    for (var i = 0; i <= horizontalLines; i++) {
      final y = rect.top + rect.height * (i / horizontalLines);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  void _drawMinMaxLabels(Canvas canvas, Rect rect) {
    final style = const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontFamily: 'Tajawal',
    );

    final maxPainter = TextPainter(
      text: TextSpan(text: maxPrice.toStringAsFixed(2), style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final minPainter = TextPainter(
      text: TextSpan(text: minPrice.toStringAsFixed(2), style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    maxPainter.paint(
        canvas, Offset(rect.left + 4, rect.top - maxPainter.height));
    minPainter.paint(
        canvas, Offset(rect.left + 4, rect.bottom - minPainter.height));
  }

  void _drawXAxisLabels(Canvas canvas, Rect rect) {
    if (dates.isEmpty) return;
    final n = dates.length;
    final step = n == 1 ? 0.0 : rect.width / (n - 1);

    final style = const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 8.8,
      fontFamily: 'Tajawal',
      fontWeight: FontWeight.w700,
      height: 1.05,
    );

    for (var i = 0; i < n; i++) {
      final d = dates[i];
      final label =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}\n${d.year}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 60);

      final x = rect.left + (n == 1 ? rect.width / 2 : i * step);
      var dx = x - tp.width / 2;
      dx = dx.clamp(rect.left, rect.right - tp.width);
      tp.paint(canvas, Offset(dx, rect.bottom + 8));
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points.first, radius: 1));
      return path;
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mx = (p0.dx + p1.dx) / 2;
      final my = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, mx, my);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  double _y(double price, Rect rect, double minPrice, double range) {
    if (range == 0) return rect.center.dy;
    final t = (price - minPrice) / range;
    return rect.bottom - (t * rect.height);
  }

  void _drawTooltip({
    required Canvas canvas,
    required Offset point,
    required double price,
    required DateTime date,
    required Rect rect,
  }) {
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${price.toStringAsFixed(2)}\n$dateLabel',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 170);

    const pad = 8.0;
    final width = textPainter.width + pad * 2;
    final height = textPainter.height + pad * 2;

    var x = point.dx - width / 2;
    var y = point.dy - height - 10;
    if (x < rect.left) x = rect.left;
    if (x + width > rect.right) x = rect.right - width;
    if (y < rect.top) y = point.dy + 10;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(12),
    );
    final bg = Paint()..color = Colors.white;
    final border = Paint()
      ..color = _kSilverAccentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(tooltipRect, bg);
    canvas.drawRRect(tooltipRect, border);
    textPainter.paint(canvas, Offset(x + pad, y + pad));
  }

  @override
  bool shouldRepaint(covariant _SilverPriceChartPainter oldDelegate) {
    return oldDelegate.prices != prices ||
        oldDelegate.dates != dates ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
