import 'package:flutter/foundation.dart';
import '../services/forex_api_service.dart';

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

  // ======= Getters =======
  String get selectedCurrency => _selectedCurrency;
  GoldPrice? get currentGoldPrice => _currentGoldPrice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GoldCaliber> get calibers => _calibers;
  List<Bullion> get bullions => _bullions;
  List<double> get weeklyOuncePrices => _weeklyOuncePrices;

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

  // ======= جلب الأسعار من الـ API =======
  Future<void> fetchGoldPrices() async {
    _isLoading = true;
    _errorMessage = null;
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

      _currentGoldPrice = GoldPrice(
        ouncePrice: ouncePriceSelected,
        gramPrice: gramPriceSelected,
        change: changeSelected,
        isPositive: isPositive,
        lastUpdated: normalizedLastUpdateUtc,
        currency: _selectedCurrency,
        changePercent: latest.changePercent,
      );

      // 3) بناء عيارات وسبائك بناءً على سعر جرام 999 (الفضة النقية)
      _buildCalibers(gramPriceSelected);
      _buildBullions(gramPriceSelected);

      // 4) ✅ تحميل بيانات آخر 10 أيام (للشارت + الجدول)
      await _loadWeeklyHistory(
        usdToSelectedRate: usdToSelected,
        days: 10,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _currentGoldPrice = null;
      _weeklyOuncePrices = [];
      _calibers = [];
      _bullions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحميل بيانات تاريخية من history واستخدامها في الشارت
  Future<void> _loadWeeklyHistory({
    required double usdToSelectedRate,
    int days = 10,
  }) async {
    try {
      final List<double> usdCloses =
          await _api.getHistoryCloses(symbol: _silverSymbol, days: days);

      if (usdCloses.isEmpty) {
        _weeklyOuncePrices = [];
        return;
      }

      _weeklyOuncePrices = usdCloses
          .map((p) => double.parse(
                (p * usdToSelectedRate).toStringAsFixed(2),
              ))
          .toList();
    } catch (_) {
      _weeklyOuncePrices = [];
    }
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
