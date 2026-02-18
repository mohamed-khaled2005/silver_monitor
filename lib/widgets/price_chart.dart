import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/gold_provider.dart';
import '../utils/constants.dart';

/// ألوان فضية ثابتة لاستخدامها في الرسم
const Color _kSilverAccent = Color(0xFFCFD8DC); // فضي فاتح
const Color _kSilverAccentDark = Color(0xFF90A4AE); // فضي أغمق

class PriceChart extends StatefulWidget {
  const PriceChart({
    Key? key,
    required this.refreshTick,
  }) : super(key: key);

  /// ✅ لما الرقم ده يزيد، الشارت يعيد تحميل التاريخ (زر تحديث/تغيير عملة)
  final int refreshTick;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int? _selectedIndex;

  bool _isLoading = false;
  String? _errorMessage;
  List<double> _prices = [];
  List<DateTime> _dates = [];

  // ✅ NEW API
  static const String _baseUrl =
      'https://api.almurakib.com/conversion-apps/api.php';
  static const String _token = '11x2x2x4x3XXXWWs2a9w8xvVvWxVcJZNuzn9Oft';

  // ✅ symbol الفضة
  static const String _silverSymbol = 'silver';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void didUpdateWidget(covariant PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ يعيد التحميل فقط لما refreshTick يتغير
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoading) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'token': _token,
        'endpoint': 'history',
        'symbol': _silverSymbol,
        'type': 'commodity',
        'period': '1d',
        'level': '1',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected JSON shape');
      }
      if (decoded['status'] != true || decoded['code'] != 200) {
        throw Exception(decoded['msg']?.toString() ?? 'API Error');
      }

      final raw = decoded['response'];
      final List<_HistoryPoint> points = [];

      void handleItem(dynamic item, [String? key]) {
        if (item is! Map) return;

        // history ممكن ييجي c مباشرة أو داخل active.c
        dynamic c = item['c'];
        if (c == null && item['active'] is Map) {
          c = (item['active'] as Map)['c'];
        }

        final tm = item['tm'];
        final t = item['t'];

        final double? close =
            c is num ? c.toDouble() : double.tryParse(c?.toString() ?? '');
        if (close == null) return;

        DateTime? date;

        // 1) tm مثل: "2026-01-18 23:00:00"
        date = _parseTmAsUtc(tm);

        // 2) t (epoch)
        date ??= _parseEpochSmart(t);

        // 3) key timestamp (لو response Map)
        if (date == null && key != null) {
          final maybe = num.tryParse(key);
          if (maybe != null) date = _parseEpochSmart(maybe);
        }

        date ??= DateTime.now().toUtc();
        points.add(_HistoryPoint(date, close));
      }

      if (raw is Map) {
        raw.forEach((k, v) => handleItem(v, k.toString()));
      } else if (raw is List) {
        for (final item in raw) {
          handleItem(item);
        }
      }

      if (points.isEmpty) throw Exception('No history points');

      // ✅ ترتيب + إزالة تكرار اليوم (نحتفظ بآخر شمعة لليوم)
      points.sort((a, b) => a.date.compareTo(b.date));
      final byDay = <String, _HistoryPoint>{};
      for (final p in points) {
        byDay[_dayKey(p.date)] = p;
      }
      final deduped = byDay.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // ✅ آخر 7 أيام
      final lastPoints =
          deduped.length > 7 ? deduped.sublist(deduped.length - 7) : deduped;

      // ✅ لو التواريخ بايظة (زي 1970) نولّد تواريخ صحيحة
      final fixedDates =
          _ensureValidRecentDates(lastPoints.map((e) => e.date).toList());

      // ✅ تحويل السعر لعملة المستخدم بنفس منطق التطبيق
      final provider = Provider.of<GoldProvider>(context, listen: false);
      final currency = provider.selectedCurrency;
      final currentPrice = provider.currentGoldPrice;

      List<double> closes;

      if (currency == 'USD' || currentPrice == null) {
        closes = lastPoints.map((e) => e.close).toList();
      } else {
        final latestUsdClose = lastPoints.last.close;
        double? rate;
        if (latestUsdClose > 0) {
          rate = currentPrice.ouncePrice / latestUsdClose;
        }

        if (rate == null || rate <= 0 || rate.isNaN || rate.isInfinite) {
          closes = lastPoints.map((e) => e.close).toList();
        } else {
          closes = lastPoints.map((e) => e.close * rate!).toList();
        }
      }

      if (!mounted) return;
      setState(() {
        _prices = closes;
        _dates = fixedDates.map((d) => d.toLocal()).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر تحميل الرسم البياني، حاول لاحقًا.';
      });
    }
  }

  // ===================== Helpers (Dates) =====================

  String _dayKey(DateTime dt) {
    final d = dt.toUtc();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  DateTime? _parseTmAsUtc(dynamic tm) {
    if (tm == null) return null;
    final s0 = tm.toString().trim();
    if (s0.isEmpty) return null;

    var s = s0;
    if (!s.contains('T')) s = s.replaceFirst(' ', 'T');

    final hasZone = s.endsWith('Z') ||
        s.contains('+') ||
        s.contains(RegExp(r'-\d{2}:\d{2}$'));
    if (!hasZone) s = '${s}Z';

    try {
      return DateTime.parse(s).toUtc();
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseEpochSmart(dynamic v) {
    if (v == null) return null;

    num? n;
    if (v is num) n = v;
    if (v is String) n = num.tryParse(v.trim());
    if (n == null) return null;

    final e = n.abs();

    // nanoseconds
    if (e >= 1000000000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch((n / 1000).round(),
              isUtc: true)
          .toUtc();
    }
    // microseconds
    if (e >= 1000000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(n.round(), isUtc: true)
          .toUtc();
    }
    // milliseconds
    if (e >= 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(n.round(), isUtc: true)
          .toUtc();
    }
    // seconds
    return DateTime.fromMillisecondsSinceEpoch((n * 1000).round(), isUtc: true)
        .toUtc();
  }

  bool _isValidDate(DateTime dt) {
    final y = dt.toLocal().year;
    return y >= 2000 && y <= 2100;
  }

  List<DateTime> _ensureValidRecentDates(List<DateTime> dates) {
    if (dates.isEmpty) return [];
    final allValid = dates.every(_isValidDate);
    if (allValid) return dates;

    final n = dates.length;
    final end = DateTime.now().toLocal();
    final start = end.subtract(Duration(days: math.max(1, n - 1)));
    final totalSeconds = end.difference(start).inSeconds;

    return List.generate(n, (i) {
      if (n == 1) return end;
      final t = i / (n - 1);
      final sec = (t * totalSeconds).round();
      return start.add(Duration(seconds: sec));
    });
  }

  // ===================== Touch =====================

  void _handleTouch(Offset localPosition, double width, int length) {
    if (length <= 0 || width <= 0) return;

    const double horizontalPadding = 16.0;
    final double usableWidth =
        (width - horizontalPadding * 2).clamp(1, width);

    double x = localPosition.dx;
    if (x < horizontalPadding) x = horizontalPadding;
    if (x > width - horizontalPadding) x = width - horizontalPadding;

    if (length == 1) {
      setState(() => _selectedIndex = 0);
      return;
    }

    final double relativeX = x - horizontalPadding;
    final double xStep = usableWidth / (length - 1);
    final int index = (relativeX / xStep).round().clamp(0, length - 1);

    setState(() => _selectedIndex = index);
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_kSilverAccent),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_prices.isEmpty || _dates.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات متاحة للرسم البياني',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final prices = _prices;
    final dates = _dates;
    final length = prices.length;

    final double maxPrice = prices.reduce(math.max);
    final double minPrice = prices.reduce(math.min);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: (d) => _handleTouch(d.localPosition, size.width, length),
          onPanUpdate: (d) => _handleTouch(d.localPosition, size.width, length),
          onTapDown: (d) => _handleTouch(d.localPosition, size.width, length),
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

class _HistoryPoint {
  final DateTime date;
  final double close;
  _HistoryPoint(this.date, this.close);
}

class _SilverPriceChartPainter extends CustomPainter {
  final List<double> prices;
  final List<DateTime> dates;
  final double maxPrice;
  final double minPrice;
  final int? selectedIndex;

  static const EdgeInsets chartPadding = EdgeInsets.fromLTRB(16, 16, 16, 62);

  _SilverPriceChartPainter({
    required this.prices,
    required this.dates,
    required this.maxPrice,
    required this.minPrice,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final Rect chartRect = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.horizontal,
      size.height - chartPadding.vertical,
    );

    if (chartRect.width <= 0 || chartRect.height <= 0) return;

    _drawBackground(canvas, chartRect);
    _drawGrid(canvas, chartRect);
    _drawMinMaxLabels(canvas, chartRect);
    _drawXAxisLabelsTwoLines(canvas, chartRect);

    final double rawRange = maxPrice - minPrice;
    final double priceRange = rawRange == 0 ? 1.0 : rawRange;

    final List<Offset> points = [];
    if (prices.length == 1) {
      final x = chartRect.left + chartRect.width / 2;
      final y = _getYPosition(prices[0], chartRect, minPrice, priceRange);
      points.add(Offset(x, y));
    } else {
      final xStep = chartRect.width / (prices.length - 1);
      for (int i = 0; i < prices.length; i++) {
        final x = chartRect.left + i * xStep;
        final y = _getYPosition(prices[i], chartRect, minPrice, priceRange);
        points.add(Offset(x, y));
      }
    }

    final Path smoothPath = _createSmoothPath(points);
    final Path fillPath = Path.from(smoothPath)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _kSilverAccent.withAlpha((0.25 * 255).toInt()),
          _kSilverAccent.withAlpha((0.03 * 255).toInt()),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final Paint linePaint = Paint()
      ..color = _kSilverAccentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(smoothPath, linePaint);

    final Paint dotPaint = Paint()
      ..color = _kSilverAccent
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3.0, dotPaint);
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < prices.length) {
      _drawTooltip(
        canvas: canvas,
        chartRect: chartRect,
        points: points,
        index: selectedIndex!,
      );
    }
  }

  void _drawBackground(Canvas canvas, Rect rect) {
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.cardDark,
          AppColors.cardLight.withAlpha((0.9 * 255).toInt()),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      bgPaint,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withAlpha((0.08 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const int horizontalLines = 4;
    for (int i = 0; i <= horizontalLines; i++) {
      final double y = rect.top + rect.height * (i / horizontalLines);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    final Paint baseLine = Paint()
      ..color = Colors.white.withAlpha((0.10 * 255).toInt())
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
      baseLine,
    );
  }

  void _drawMinMaxLabels(Canvas canvas, Rect rect) {
    final TextStyle labelStyle = const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontFamily: 'Tajawal',
    );

    final maxPainter = TextPainter(
      text: TextSpan(text: maxPrice.toStringAsFixed(2), style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final minPainter = TextPainter(
      text: TextSpan(text: minPrice.toStringAsFixed(2), style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    maxPainter.paint(canvas, Offset(rect.left + 4, rect.top - maxPainter.height));
    minPainter.paint(
        canvas, Offset(rect.left + 4, rect.bottom - minPainter.height));
  }

  String _fmtTwoLine(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m\n$y';
  }

  void _drawXAxisLabelsTwoLines(Canvas canvas, Rect rect) {
    if (dates.isEmpty || prices.length != dates.length) return;

    final n = dates.length;
    final xStep = n == 1 ? 0.0 : rect.width / (n - 1);

    double fs = 9.6;
    if (n > 1) {
      if (xStep < 46) fs = 9.0;
      if (xStep < 40) fs = 8.6;
      if (xStep < 34) fs = 8.2;
    }

    final style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: fs,
      fontFamily: 'Tajawal',
      fontWeight: FontWeight.w700,
      height: 1.05,
    );

    final tickPaint = Paint()
      ..color = Colors.white.withAlpha((0.12 * 255).toInt())
      ..strokeWidth = 1;

    for (int i = 0; i < n; i++) {
      final label = _fmtTwoLine(dates[i]);

      final tp = TextPainter(
        text: TextSpan(text: label, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);

      final x = rect.left + (n == 1 ? rect.width / 2 : i * xStep);

      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x, rect.bottom + 4),
        tickPaint,
      );

      double dx = x - tp.width / 2;
      dx = dx.clamp(rect.left, rect.right - tp.width);

      tp.paint(canvas, Offset(dx, rect.bottom + 8));
    }
  }

  Path _createSmoothPath(List<Offset> points) {
    final Path path = Path();
    if (points.isEmpty) return path;

    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points.first, radius: 1));
      return path;
    }

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mx = (p0.dx + p1.dx) / 2;
      final my = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, mx, my);
    }

    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  void _drawTooltip({
    required Canvas canvas,
    required Rect chartRect,
    required List<Offset> points,
    required int index,
  }) {
    final point = points[index];
    final price = prices[index];
    final date = dates[index];

    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    final dateLabel = '$d/$m/$y';
    final priceText = price.toStringAsFixed(2);

    final Paint linePaint = Paint()
      ..color = _kSilverAccent.withAlpha((0.35 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(point.dx, chartRect.top),
      Offset(point.dx, chartRect.bottom),
      linePaint,
    );

    final Paint highlightDot = Paint()
      ..color = _kSilverAccentDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 5.0, highlightDot);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$priceText\n$dateLabel',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 170);

    const padding = 8.0;
    final boxWidth = textPainter.width + padding * 2;
    final boxHeight = textPainter.height + padding * 2;

    double boxX = point.dx - boxWidth / 2;
    double boxY = point.dy - boxHeight - 10;

    if (boxX < chartRect.left) boxX = chartRect.left;
    if (boxX + boxWidth > chartRect.right) boxX = chartRect.right - boxWidth;
    if (boxY < chartRect.top) boxY = point.dy + 10;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
      const Radius.circular(12),
    );

    final Paint tooltipBgPaint = Paint()..color = Colors.white;
    final Paint tooltipBorderPaint = Paint()
      ..color = _kSilverAccentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(tooltipRect, tooltipBgPaint);
    canvas.drawRRect(tooltipRect, tooltipBorderPaint);

    textPainter.paint(canvas, Offset(boxX + padding, boxY + padding));
  }

  double _getYPosition(
    double price,
    Rect rect,
    double minPrice,
    double priceRange,
  ) {
    if (priceRange == 0) return rect.center.dy;
    final t = (price - minPrice) / priceRange;
    return rect.bottom - (t * rect.height);
  }

  @override
  bool shouldRepaint(covariant _SilverPriceChartPainter oldDelegate) {
    return oldDelegate.prices != prices ||
        oldDelegate.dates != dates ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.minPrice != minPrice;
  }
}
