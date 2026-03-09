import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';

const Color _kSilverAccent = Color(0xFFCFD8DC);
const Color _kSilverAccentDark = Color(0xFF90A4AE);

class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.refreshTick,
    required this.prices,
    required this.range,
    this.latestDateUtc,
    this.currencyCode = '',
  });

  final int refreshTick;
  final List<double> prices;
  final ChartRange range;
  final DateTime? latestDateUtc;
  final String currencyCode;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int? _selectedGlobalIndex;
  double _zoom = 1.0;
  double _windowStartRatio = 0.0;
  double _scaleStartZoom = 1.0;

  @override
  void didUpdateWidget(covariant PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = oldWidget.range != widget.range ||
        !identical(oldWidget.prices, widget.prices);
    if (changed) {
      _selectedGlobalIndex = null;
      _zoom = 1.0;
      _windowStartRatio = 0.0;
    }
  }

  double _maxZoom(int totalCount) {
    if (totalCount <= 20) return 1.0;
    final candidate = totalCount / 20.0;
    return candidate.clamp(1.0, 12.0);
  }

  int _visibleCount(
    int totalCount, {
    double? zoom,
  }) {
    if (totalCount <= 2) return totalCount;
    final z = zoom ?? _zoom;
    final raw = (totalCount / z).round();
    return raw.clamp(2, totalCount);
  }

  int _windowStartIndex(
    int totalCount, {
    double? zoom,
    double? ratio,
  }) {
    final visible = _visibleCount(totalCount, zoom: zoom);
    final maxStart = math.max(0, totalCount - visible);
    if (maxStart == 0) return 0;
    final r = ratio ?? _windowStartRatio;
    return (r * maxStart).round().clamp(0, maxStart);
  }

  void _setWindowStartIndex(
    int totalCount,
    int startIndex, {
    double? zoom,
  }) {
    final visible = _visibleCount(totalCount, zoom: zoom);
    final maxStart = math.max(0, totalCount - visible);
    if (maxStart == 0) {
      _windowStartRatio = 0.0;
      return;
    }
    _windowStartRatio = startIndex.clamp(0, maxStart) / maxStart;
  }

  void _resetView() {
    setState(() {
      _zoom = 1.0;
      _windowStartRatio = 0.0;
      _selectedGlobalIndex = null;
    });
  }

  void _handleTouch({
    required Offset localPosition,
    required Size size,
    required int visibleLength,
    required int startIndex,
  }) {
    if (visibleLength <= 0 || size.width <= 0) return;

    const horizontalPadding = 16.0;
    final usableWidth =
        (size.width - horizontalPadding * 2).clamp(1.0, size.width);
    var x = localPosition.dx;
    if (x < horizontalPadding) x = horizontalPadding;
    if (x > size.width - horizontalPadding) x = size.width - horizontalPadding;

    final step =
        visibleLength <= 1 ? usableWidth : usableWidth / (visibleLength - 1);
    final relative = x - horizontalPadding;
    final localIdx = (relative / step).round().clamp(0, visibleLength - 1);

    setState(() => _selectedGlobalIndex = startIndex + localIdx);
  }

  void _handleScaleStart(ScaleStartDetails _) {
    _scaleStartZoom = _zoom;
  }

  void _handleScaleUpdate({
    required ScaleUpdateDetails details,
    required Size size,
    required int totalCount,
  }) {
    if (totalCount <= 2) return;

    final chartWidth =
        (size.width - _SilverPriceChartPainter.chartPadding.horizontal)
            .clamp(1.0, size.width);

    if (details.pointerCount > 1) {
      final oldStart = _windowStartIndex(totalCount);
      final oldVisible = _visibleCount(totalCount);
      final maxZoom = _maxZoom(totalCount);
      final nextZoom = (_scaleStartZoom * details.scale).clamp(1.0, maxZoom);
      var nextStart = oldStart;

      if ((nextZoom - _zoom).abs() > 0.0001) {
        final focalT = ((details.localFocalPoint.dx -
                    _SilverPriceChartPainter.chartPadding.left) /
                chartWidth)
            .clamp(0.0, 1.0);
        final focalData = oldStart + focalT * math.max(0, oldVisible - 1);
        final newVisible = _visibleCount(totalCount, zoom: nextZoom);
        final maxStart = math.max(0, totalCount - newVisible);
        nextStart = (focalData - focalT * math.max(0, newVisible - 1))
            .round()
            .clamp(0, maxStart);
      }

      final visible = _visibleCount(totalCount, zoom: nextZoom);
      final maxStart = math.max(0, totalCount - visible);
      if (maxStart > 0 && details.focalPointDelta.dx != 0) {
        final delta = (-details.focalPointDelta.dx / chartWidth) * visible;
        nextStart = (nextStart + delta.round()).clamp(0, maxStart);
      }

      setState(() {
        _zoom = nextZoom;
        _setWindowStartIndex(totalCount, nextStart, zoom: nextZoom);
        _selectedGlobalIndex = null;
      });
      return;
    }

    if (_zoom > 1.01) {
      final visible = _visibleCount(totalCount);
      final maxStart = math.max(0, totalCount - visible);
      if (maxStart <= 0) return;

      final oldStart = _windowStartIndex(totalCount);
      final delta = (-details.focalPointDelta.dx / chartWidth) * visible;
      final nextStart = (oldStart + delta.round()).clamp(0, maxStart);

      if (nextStart == oldStart) return;
      setState(() => _setWindowStartIndex(totalCount, nextStart));
      return;
    }

    final start = _windowStartIndex(totalCount);
    final visible = _visibleCount(totalCount);
    _handleTouch(
      localPosition: details.localFocalPoint,
      size: size,
      visibleLength: visible,
      startIndex: start,
    );
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
    final prices = widget.prices;

    if (prices.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد بيانات للرسم البياني.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final dates = _buildDates(
      count: prices.length,
      latest: widget.latestDateUtc,
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final totalCount = prices.length;
        final visibleCount = _visibleCount(totalCount);
        final startIndex = _windowStartIndex(totalCount);
        final endIndex = math.min(totalCount, startIndex + visibleCount);

        final viewPrices = prices.sublist(startIndex, endIndex);
        final viewDates = dates.sublist(startIndex, endIndex);
        final viewMax = viewPrices.reduce(math.max);
        final viewMin = viewPrices.reduce(math.min);

        int? selectedVisibleIndex;
        if (_selectedGlobalIndex != null &&
            _selectedGlobalIndex! >= startIndex &&
            _selectedGlobalIndex! < endIndex) {
          selectedVisibleIndex = _selectedGlobalIndex! - startIndex;
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) => _handleTouch(
            localPosition: d.localPosition,
            size: size,
            visibleLength: viewPrices.length,
            startIndex: startIndex,
          ),
          onLongPressStart: (d) => _handleTouch(
            localPosition: d.localPosition,
            size: size,
            visibleLength: viewPrices.length,
            startIndex: startIndex,
          ),
          onLongPressMoveUpdate: (d) => _handleTouch(
            localPosition: d.localPosition,
            size: size,
            visibleLength: viewPrices.length,
            startIndex: startIndex,
          ),
          onDoubleTap: _resetView,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: (d) => _handleScaleUpdate(
            details: d,
            size: size,
            totalCount: totalCount,
          ),
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _SilverPriceChartPainter(
                prices: viewPrices,
                dates: viewDates,
                range: widget.range,
                currencyCode: widget.currencyCode,
                maxPrice: viewMax,
                minPrice: viewMin,
                selectedIndex: selectedVisibleIndex,
                isZoomed: _zoom > 1.01,
                visibleCount: viewPrices.length,
                totalCount: totalCount,
              ),
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
    required this.range,
    required this.currencyCode,
    required this.maxPrice,
    required this.minPrice,
    required this.selectedIndex,
    required this.isZoomed,
    required this.visibleCount,
    required this.totalCount,
  });

  final List<double> prices;
  final List<DateTime> dates;
  final ChartRange range;
  final String currencyCode;
  final double maxPrice;
  final double minPrice;
  final int? selectedIndex;
  final bool isZoomed;
  final int visibleCount;
  final int totalCount;

  static const EdgeInsets chartPadding = EdgeInsets.fromLTRB(14, 12, 14, 34);

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
    if (isZoomed) {
      _drawZoomHint(canvas, chartRect);
    }

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
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    if (points.length <= 50) {
      final dotPaint = Paint()..color = _kSilverAccent;
      for (final p in points) {
        canvas.drawCircle(p, 2.1, dotPaint);
      }
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];
      _drawSelectionGuide(canvas, selectedPoint, chartRect);
      _drawTooltip(
        canvas: canvas,
        point: selectedPoint,
        price: prices[selectedIndex!],
        date: dates[selectedIndex!],
        rect: chartRect,
      );
    }
  }

  void _drawBackground(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF111720),
          Color(0xFF0E141C),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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

    const verticalLines = 4;
    for (var i = 0; i <= verticalLines; i++) {
      final x = rect.left + rect.width * (i / verticalLines);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }
  }

  void _drawMinMaxLabels(Canvas canvas, Rect rect) {
    const style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 9.6,
      fontFamily: 'Tajawal',
      fontWeight: FontWeight.w700,
    );

    final maxPainter = TextPainter(
      text: TextSpan(text: maxPrice.toStringAsFixed(2), style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final minPainter = TextPainter(
      text: TextSpan(text: minPrice.toStringAsFixed(2), style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    _drawPriceTag(
      canvas: canvas,
      rect: rect,
      painter: maxPainter,
      top: rect.top + 2,
    );
    _drawPriceTag(
      canvas: canvas,
      rect: rect,
      painter: minPainter,
      top: rect.bottom - minPainter.height - 8,
    );
  }

  void _drawXAxisLabels(Canvas canvas, Rect rect) {
    if (dates.isEmpty) return;
    final n = dates.length;
    final style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: range == ChartRange.year ? 8.4 : 8.9,
      fontFamily: 'Tajawal',
      fontWeight: FontWeight.w700,
      height: 1.0,
    );
    final indices = _xLabelIndices(n, _targetLabelCount(range));
    final step = n == 1 ? 0.0 : rect.width / (n - 1);

    for (final i in indices) {
      final d = dates[i];
      final label = _xAxisDateLabel(d);
      final tp = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 48);

      final x = rect.left + (n == 1 ? rect.width / 2 : i * step);
      var dx = x - tp.width / 2;
      dx = dx.clamp(rect.left, rect.right - tp.width);
      tp.paint(canvas, Offset(dx, rect.bottom + 6));
    }
  }

  int _targetLabelCount(ChartRange selectedRange) {
    switch (selectedRange) {
      case ChartRange.week:
        return 4;
      case ChartRange.month:
        return 5;
      case ChartRange.threeMonths:
        return 6;
      case ChartRange.sixMonths:
        return 6;
      case ChartRange.year:
        return 7;
    }
  }

  List<int> _xLabelIndices(int count, int targetCount) {
    if (count <= 1) return <int>[0];
    if (count <= targetCount) {
      return List<int>.generate(count, (i) => i);
    }

    final out = <int>{0, count - 1};
    final slots = targetCount - 1;
    for (var i = 1; i < slots; i++) {
      final t = i / slots;
      out.add((t * (count - 1)).round().clamp(0, count - 1));
    }
    final sorted = out.toList()..sort();
    return sorted;
  }

  String _xAxisDateLabel(DateTime date) {
    if (range == ChartRange.year) {
      return '${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
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

  void _drawSelectionGuide(Canvas canvas, Offset point, Rect rect) {
    final guidePaint = Paint()
      ..color = _kSilverAccent.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(point.dx, rect.top),
      Offset(point.dx, rect.bottom),
      guidePaint,
    );

    final haloPaint = Paint()
      ..color = _kSilverAccentDark.withValues(alpha: 0.28);
    final corePaint = Paint()..color = Colors.white;
    final centerPaint = Paint()..color = _kSilverAccentDark;
    canvas.drawCircle(point, 8, haloPaint);
    canvas.drawCircle(point, 4.4, corePaint);
    canvas.drawCircle(point, 2.5, centerPaint);
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
    final valueLabel = currencyCode.isEmpty
        ? price.toStringAsFixed(2)
        : '${price.toStringAsFixed(2)} $currencyCode';
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$valueLabel\n$dateLabel',
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.97),
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
    final bg = Paint()..color = const Color(0xFF0D1219);
    final border = Paint()
      ..color = _kSilverAccent.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(tooltipRect, bg);
    canvas.drawRRect(tooltipRect, border);
    textPainter.paint(canvas, Offset(x + pad, y + pad));
  }

  void _drawPriceTag({
    required Canvas canvas,
    required Rect rect,
    required TextPainter painter,
    required double top,
  }) {
    const horizontalPadding = 6.0;
    const verticalPadding = 3.0;

    final width = painter.width + horizontalPadding * 2;
    final height = painter.height + verticalPadding * 2;
    final left = rect.right - width - 2;

    final tagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      const Radius.circular(8),
    );
    final tagPaint = Paint()..color = Colors.black.withValues(alpha: 0.32);
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(tagRect, tagPaint);
    canvas.drawRRect(tagRect, borderPaint);
    painter.paint(
      canvas,
      Offset(left + horizontalPadding, top + verticalPadding),
    );
  }

  void _drawZoomHint(Canvas canvas, Rect rect) {
    const style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontFamily: 'Tajawal',
      fontWeight: FontWeight.w700,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: 'عرض $visibleCount / $totalCount',
        style: style,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const horizontalPadding = 7.0;
    const verticalPadding = 4.0;
    final width = painter.width + horizontalPadding * 2;
    final height = painter.height + verticalPadding * 2;
    final hintRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + 2, rect.top + 2, width, height),
      const Radius.circular(8),
    );
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.36);
    canvas.drawRRect(hintRect, bgPaint);
    painter.paint(
      canvas,
      Offset(
        rect.left + 2 + horizontalPadding,
        rect.top + 2 + verticalPadding,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SilverPriceChartPainter oldDelegate) {
    return oldDelegate.prices != prices ||
        oldDelegate.dates != dates ||
        oldDelegate.range != range ||
        oldDelegate.currencyCode != currencyCode ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isZoomed != isZoomed ||
        oldDelegate.visibleCount != visibleCount ||
        oldDelegate.totalCount != totalCount;
  }
}
