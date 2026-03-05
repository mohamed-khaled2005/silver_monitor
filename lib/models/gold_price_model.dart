class GoldPrice {
  final double ouncePrice;
  final double gramPrice;
  final double change; // التغيير بالقيمة المطلقة
  final bool isPositive;
  final DateTime lastUpdated;
  final String currency;
  final String changePercent; // التغيير بالنسبة المئوية (زي +0.58%)

  GoldPrice({
    required this.ouncePrice,
    required this.gramPrice,
    required this.change,
    required this.isPositive,
    required this.lastUpdated,
    required this.currency,
    required this.changePercent,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      ouncePrice: json['ouncePrice']?.toDouble() ?? 0.0,
      gramPrice: json['gramPrice']?.toDouble() ?? 0.0,
      change: json['change']?.toDouble() ?? 0.0,
      isPositive: json['isPositive'] ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      currency: json['currency'] ?? 'USD',
      changePercent: json['changePercent']?.toString() ?? '0%',
    );
  }
}

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

class Bullion {
  final String type;
  final double weight;
  final double price;
  final String image;

  Bullion({
    required this.type,
    required this.weight,
    required this.price,
    required this.image,
  });
}
