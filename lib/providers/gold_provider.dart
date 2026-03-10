import 'package:flutter/foundation.dart';
import '../services/forex_api_service.dart';

enum ChartRange {
  week,
  month,
  threeMonths,
  sixMonths,
  year,
}

extension ChartRangeX on ChartRange {
  int get days {
    switch (this) {
      case ChartRange.week:
        return 7;
      case ChartRange.month:
        return 30;
      case ChartRange.threeMonths:
        return 90;
      case ChartRange.sixMonths:
        return 180;
      case ChartRange.year:
        return 365;
    }
  }

  String get labelAr {
    switch (this) {
      case ChartRange.week:
        return 'أسبوع';
      case ChartRange.month:
        return 'شهر';
      case ChartRange.threeMonths:
        return '3 شهور';
      case ChartRange.sixMonths:
        return '6 شهور';
      case ChartRange.year:
        return 'سنة';
    }
  }
}

/// موديل سعر الفضة (أونصة + جرام)
class GoldPrice {
  final double ouncePrice;
  final double gramPrice;
  final double change;
  final bool isPositive;
  final DateTime lastUpdated;
  final String currency;
  final String changePercent;

  GoldPrice({
    required this.ouncePrice,
    required this.gramPrice,
    required this.change,
    required this.isPositive,
    required this.lastUpdated,
    required this.currency,
    required this.changePercent,
  });
}

/// موديل عيار فضة
class GoldCaliber {
  final String name;
  final double pricePerGram;
  final String purity;

  GoldCaliber({
    required this.name,
    required this.pricePerGram,
    required this.purity,
  });
}

/// موديل سبيكة فضة
class Bullion {
  final String type;
  final double weight; // بالجرام
  final double price;
  final String image;

  Bullion({
    required this.type,
    required this.weight,
    required this.price,
    required this.image,
  });
}

class GoldProvider with ChangeNotifier {
  final ForexApiService _api = ForexApiService();

  // ✅ Symbol الفضة الموحّد في التطبيق كله
  static const String _silverSymbol = 'XAGUSD';

  // 🟣 العملة الحالية
  String _selectedCurrency = 'USD';

  // 🟣 بيانات السعر الحالي
  GoldPrice? _currentGoldPrice;

  // 🟣 حالة التحميل + الخطأ
  bool _isLoading = false;
  String? _errorMessage;

  // 🟣 بيانات العيارات والسبائك
  List<GoldCaliber> _calibers = [];
  List<Bullion> _bullions = [];

  // 🟣 بيانات الشارت (أسعار الأونصة بالأيام)
  List<double> _weeklyOuncePrices = [];
  final Map<ChartRange, List<double>> _historyByRange =
      <ChartRange, List<double>>{};
  final Set<ChartRange> _loadingChartRanges = <ChartRange>{};
  ChartRange _selectedChartRange = ChartRange.week;
  double _usdToSelectedRate = 1.0;
  int _historyRequestId = 0;
  Future<void>? _analysisPreloadTask;
  PivotPointsData? _pivotPoints;
  bool _isPivotPointsLoading = false;
  String? _pivotPointsError;

  // ======= Getters =======
  String get selectedCurrency => _selectedCurrency;
  GoldPrice? get currentGoldPrice => _currentGoldPrice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GoldCaliber> get calibers => _calibers;
  List<Bullion> get bullions => _bullions;
  List<double> get weeklyOuncePrices =>
      _historyByRange[ChartRange.week] ?? _weeklyOuncePrices;
  ChartRange get selectedChartRange => _selectedChartRange;
  List<double> get selectedChartPrices =>
      _historyByRange[_selectedChartRange] ?? const <double>[];
  PivotPointsData? get pivotPoints => _pivotPoints;
  bool get isPivotPointsLoading => _isPivotPointsLoading;
  String? get pivotPointsError => _pivotPointsError;

  List<double> chartPricesFor(ChartRange range) =>
      _historyByRange[range] ?? const <double>[];

  bool isChartRangeLoading(ChartRange range) =>
      _loadingChartRanges.contains(range);
  bool get hasAllChartRangesLoaded =>
      ChartRange.values.every((r) => _historyByRange[r]?.isNotEmpty ?? false);

  Future<void> ensurePivotPointsLoaded({bool force = false}) async {
    if (!force && _pivotPoints != null) {
      return;
    }
    if (_isPivotPointsLoading) {
      return;
    }

    if (_currentGoldPrice == null) {
      await fetchGoldPrices();
      return;
    }

    _isPivotPointsLoading = true;
    _pivotPointsError = null;
    notifyListeners();

    try {
      final pivotUsd = await _api.getPivotPoints(
        symbol: _silverSymbol,
        period: '1D',
      );
      _pivotPoints = pivotUsd.scaled(_usdToSelectedRate);
    } catch (e) {
      _pivotPointsError = e.toString();
    } finally {
      _isPivotPointsLoading = false;
      notifyListeners();
    }
  }

  // ======= إعداد أولي =======
  Future<void> initializeData() async {
    _buildCalibers(0.0);
    _buildBullions(0.0);
    await fetchGoldPrices();
  }

  void setCurrency(String currency, {bool fetchNow = true}) {
    _selectedCurrency = currency;
    if (fetchNow) {
      fetchGoldPrices();
    }
    notifyListeners();
  }

  Future<void> setChartRange(
    ChartRange range, {
    bool loadIfNeeded = true,
  }) async {
    if (_selectedChartRange == range) {
      if (loadIfNeeded) {
        await ensureSelectedChartRangeLoaded();
      }
      return;
    }

    _selectedChartRange = range;
    notifyListeners();
    if (loadIfNeeded) {
      await ensureSelectedChartRangeLoaded();
    }
  }

  Future<void> ensureSelectedChartRangeLoaded() async {
    await _ensureHistoryForRange(_selectedChartRange);
  }

  Future<void> preloadAnalysisChartRanges({bool force = false}) async {
    if (_currentGoldPrice == null) return;
    if (!force && hasAllChartRangesLoaded) return;

    final existingTask = _analysisPreloadTask;
    if (existingTask != null) {
      await existingTask;
      return;
    }

    final requestId = _historyRequestId;
    final task = _preloadAllChartRangesFromYearHistory(
      requestId: requestId,
      usdToSelectedRate: _usdToSelectedRate,
    );
    _analysisPreloadTask = task;
    try {
      await task;
    } finally {
      if (identical(_analysisPreloadTask, task)) {
        _analysisPreloadTask = null;
      }
    }
  }

  // ======= جلب الأسعار من الـ API =======
  Future<void> fetchGoldPrices() async {
    _isLoading = true;
    _isPivotPointsLoading = true;
    _errorMessage = null;
    _pivotPointsError = null;
    _pivotPoints = null;
    final int requestId = ++_historyRequestId;
    notifyListeners();

    try {
      // 1) تحويل من USD → العملة المختارة
      double usdToSelected = 1.0;
      if (_selectedCurrency != 'USD') {
        usdToSelected = await _api.convert(
          from: 'USD',
          to: _selectedCurrency,
          amount: 1.0,
        );
      }

      // 2) آخر سعر للفضة: XAGUSD
      final latest = await _api.getLatestPrice(symbol: _silverSymbol);
      final double usdOuncePrice = latest.close;

      // سعر أونصة الفضة بالعملة المختارة
      final double ouncePriceSelected = usdOuncePrice * usdToSelected;

      // أونصة تروي ≈ 31.1035 جرام
      final double gramPriceSelected = ouncePriceSelected / 31.1035;

      // التغيير للأونصة بالعملة المختارة
      final double changeSelected = latest.change * usdToSelected;
      final bool isPositive = changeSelected >= 0;
      final DateTime normalizedLastUpdateUtc = latest.lastUpdate.isUtc
          ? latest.lastUpdate
          : latest.lastUpdate.toUtc();

      _usdToSelectedRate = usdToSelected;
      _currentGoldPrice = GoldPrice(
        ouncePrice: ouncePriceSelected,
        gramPrice: gramPriceSelected,
        change: changeSelected,
        isPositive: isPositive,
        lastUpdated: normalizedLastUpdateUtc,
        currency: _selectedCurrency,
        changePercent: latest.changePercent,
      );

      try {
        final pivotUsd = await _api.getPivotPoints(
          symbol: _silverSymbol,
          period: '1D',
        );
        _pivotPoints = pivotUsd.scaled(_usdToSelectedRate);
        _pivotPointsError = null;
      } catch (e) {
        _pivotPoints = null;
        _pivotPointsError = e.toString();
      }

      // 3) بناء عيارات وسبائك بناءً على سعر جرام 999 (الفضة النقية)
      _buildCalibers(gramPriceSelected);
      _buildBullions(gramPriceSelected);

      // 4) تحميل بيانات أسبوع + شهر (لتغذية جدول آخر 10 أيام) ثم الفترة المختارة للتحليل
      _historyByRange.clear();
      _loadingChartRanges.clear();
      _analysisPreloadTask = null;
      _weeklyOuncePrices = [];

      await _loadHistoryForRange(
        range: ChartRange.week,
        usdToSelectedRate: _usdToSelectedRate,
        requestId: requestId,
        notify: false,
      );
      await _loadHistoryForRange(
        range: ChartRange.month,
        usdToSelectedRate: _usdToSelectedRate,
        requestId: requestId,
        notify: false,
      );
      if (_selectedChartRange != ChartRange.week &&
          _selectedChartRange != ChartRange.month) {
        await _loadHistoryForRange(
          range: _selectedChartRange,
          usdToSelectedRate: _usdToSelectedRate,
          requestId: requestId,
          notify: false,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentGoldPrice = null;
      _pivotPoints = null;
      _pivotPointsError = null;
      _weeklyOuncePrices = [];
      _historyByRange.clear();
      _loadingChartRanges.clear();
      _analysisPreloadTask = null;
      _calibers = [];
      _bullions = [];
    } finally {
      _isLoading = false;
      _isPivotPointsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureHistoryForRange(ChartRange range) async {
    if (_currentGoldPrice == null) return;
    if (_historyByRange[range]?.isNotEmpty ?? false) return;
    await _loadHistoryForRange(
      range: range,
      usdToSelectedRate: _usdToSelectedRate,
      requestId: _historyRequestId,
      notify: true,
    );
  }

  Future<void> _loadHistoryForRange({
    required ChartRange range,
    required double usdToSelectedRate,
    required int requestId,
    bool notify = true,
  }) async {
    if (_loadingChartRanges.contains(range)) return;

    _loadingChartRanges.add(range);
    if (notify) {
      notifyListeners();
    }

    try {
      final List<double> usdCloses = await _api.getHistoryCloses(
        symbol: _silverSymbol,
        days: range.days,
      );

      if (requestId != _historyRequestId) {
        return;
      }

      if (usdCloses.isEmpty) {
        _historyByRange[range] = <double>[];
        if (range == ChartRange.week) {
          _weeklyOuncePrices = <double>[];
        }
        return;
      }

      final converted = usdCloses
          .map((p) => double.parse(
                (p * usdToSelectedRate).toStringAsFixed(2),
              ))
          .toList();

      _historyByRange[range] = converted;
      if (range == ChartRange.week) {
        _weeklyOuncePrices = converted;
      }
    } catch (_) {
      if (requestId != _historyRequestId) {
        return;
      }
      _historyByRange[range] = <double>[];
      if (range == ChartRange.week) {
        _weeklyOuncePrices = <double>[];
      }
    } finally {
      _loadingChartRanges.remove(range);
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> _preloadAllChartRangesFromYearHistory({
    required int requestId,
    required double usdToSelectedRate,
  }) async {
    final ranges = ChartRange.values.toSet();
    _loadingChartRanges.addAll(ranges);
    notifyListeners();

    try {
      final List<double> usdCloses = await _api.getHistoryCloses(
        symbol: _silverSymbol,
        days: ChartRange.year.days,
      );

      if (requestId != _historyRequestId) {
        return;
      }

      final List<double> converted = usdCloses
          .map((p) => double.parse((p * usdToSelectedRate).toStringAsFixed(2)))
          .toList();

      for (final range in ChartRange.values) {
        _historyByRange[range] = _tail(converted, range.days);
      }
      _weeklyOuncePrices = _historyByRange[ChartRange.week] ?? <double>[];
    } catch (_) {
      if (requestId != _historyRequestId) {
        return;
      }
      for (final range in ChartRange.values) {
        _historyByRange[range] = <double>[];
      }
      _weeklyOuncePrices = <double>[];
    } finally {
      _loadingChartRanges.removeAll(ranges);
      notifyListeners();
    }
  }

  List<double> _tail(List<double> source, int count) {
    if (source.isEmpty) return <double>[];
    if (source.length <= count) return List<double>.from(source);
    return source.sublist(source.length - count);
  }

  // ======= بناء عيارات الفضة والسبائك =======
  void _buildCalibers(double baseGramPrice999) {
    if (baseGramPrice999 <= 0) {
      _calibers = [];
      return;
    }

    double priceFor(int fineness) => baseGramPrice999 * (fineness / 999.0);

    _calibers = [
      GoldCaliber(
        name: 'عيار 999 - الفضة النقية',
        pricePerGram: priceFor(999),
        purity: '99.9%',
      ),
      GoldCaliber(
        name: 'عيار 958 - فضة بريتانيا',
        pricePerGram: priceFor(958),
        purity: '95.8%',
      ),
      GoldCaliber(
        name: 'عيار 925 - استرليني / إيطالي',
        pricePerGram: priceFor(925),
        purity: '92.5%',
      ),
      GoldCaliber(
        name: 'عيار 900 - فضة عملات',
        pricePerGram: priceFor(900),
        purity: '90%',
      ),
      GoldCaliber(
        name: 'عيار 835 - فضة أوروبية',
        pricePerGram: priceFor(835),
        purity: '83.5%',
      ),
      GoldCaliber(
        name: 'عيار 800 - فضة ألمانية',
        pricePerGram: priceFor(800),
        purity: '80%',
      ),
      GoldCaliber(
        name: 'عيار 750 - فضة منخفضة العيار',
        pricePerGram: priceFor(750),
        purity: '75%',
      ),
    ];
  }

  void _buildBullions(double baseGramPrice999) {
    if (baseGramPrice999 <= 0) {
      _bullions = [];
      return;
    }

    double priceFor(double grams) =>
        double.parse((baseGramPrice999 * grams).toStringAsFixed(2));

    _bullions = [
      Bullion(type: 'سبيكة 1 جرام', weight: 1, price: priceFor(1), image: ''),
      Bullion(type: 'سبيكة 5 جرام', weight: 5, price: priceFor(5), image: ''),
      Bullion(
          type: 'سبيكة 10 جرام', weight: 10, price: priceFor(10), image: ''),
      Bullion(
          type: 'سبيكة 20 جرام', weight: 20, price: priceFor(20), image: ''),
      Bullion(
          type: 'سبيكة 50 جرام', weight: 50, price: priceFor(50), image: ''),
      Bullion(
          type: 'سبيكة 100 جرام', weight: 100, price: priceFor(100), image: ''),
      Bullion(
          type: 'سبيكة 250 جرام', weight: 250, price: priceFor(250), image: ''),
      Bullion(
          type: 'سبيكة 500 جرام', weight: 500, price: priceFor(500), image: ''),
      Bullion(
          type: 'سبيكة 1 كجم', weight: 1000, price: priceFor(1000), image: ''),
    ];
  }

  /// حاسبة سعر الفضة بناءً على الوزن + العيار
  double calculateGoldPrice(double weight, String caliberName) {
    if (_calibers.isEmpty) return 0.0;

    final GoldCaliber caliber = _calibers.firstWhere(
      (c) => c.name == caliberName,
      orElse: () => _calibers.first,
    );

    return weight * caliber.pricePerGram;
  }
}
