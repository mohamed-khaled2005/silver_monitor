import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ظ…ظˆط¯ظٹظ„ ظٹظ…ط«ظ„ ظ†طھظٹط¬ط© latest ظ…ظ† ظ…ط²ظˆط¯ ط§ظ„ط£ط³ط¹ط§ط± (NEW API)
class LatestPrice {
  final double open;
  final double high;
  final double low;
  final double close;
  final double ask;
  final double bid;
  final double change;
  final String changePercent;
  final DateTime lastUpdate;

  LatestPrice({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.ask,
    required this.bid,
    required this.change,
    required this.changePercent,
    required this.lastUpdate,
  });

  factory LatestPrice.fromJson(Map<String, dynamic> json) {
    // NEW API may return numeric fields under `active`.
    final Map<String, dynamic> m = (json['active'] is Map)
        ? (json['active'] as Map).cast<String, dynamic>()
        : json;

    double toDoubleValue(dynamic v) =>
        v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

    DateTime? parseEpochSmart(dynamic raw) {
      if (raw == null) return null;
      final n = num.tryParse(raw.toString().trim());
      if (n == null) return null;

      final absValue = n.abs();
      if (absValue >= 1000000000000000000) {
        return DateTime.fromMicrosecondsSinceEpoch((n / 1000).round(),
                isUtc: true)
            .toUtc();
      }
      if (absValue >= 1000000000000000) {
        return DateTime.fromMicrosecondsSinceEpoch(n.round(), isUtc: true)
            .toUtc();
      }
      if (absValue >= 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n.round(), isUtc: true)
            .toUtc();
      }
      return DateTime.fromMillisecondsSinceEpoch((n * 1000).round(),
              isUtc: true)
          .toUtc();
    }

    DateTime? parseUtcString(dynamic raw) {
      final s0 = raw?.toString().trim() ?? '';
      if (s0.isEmpty) return null;

      var s = s0;
      if (s.contains(' ') && !s.contains('T')) {
        s = s.replaceFirst(' ', 'T');
      }

      final hasZone = RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(s);
      final normalized = hasZone ? s : '${s}Z';
      final dt = DateTime.tryParse(normalized);
      return dt?.toUtc();
    }

    DateTime parseServerUpdateUtc(Map<String, dynamic> obj) {
      return parseEpochSmart(obj['update']) ??
          parseUtcString(obj['updateTime']) ??
          parseUtcString(obj['tm']) ??
          parseEpochSmart(obj['t']) ??
          DateTime.now().toUtc();
    }

    DateTime lastUpdate = parseServerUpdateUtc(json);
    if (lastUpdate.year < 2000) {
      lastUpdate = parseServerUpdateUtc(m);
    }

    final dynamic chp = m['chp'] ?? m['cp'] ?? '';

    return LatestPrice(
      open: toDoubleValue(m['o']),
      high: toDoubleValue(m['h']),
      low: toDoubleValue(m['l']),
      close: toDoubleValue(m['c']),
      ask: toDoubleValue(m['a']),
      bid: toDoubleValue(m['b']),
      change: toDoubleValue(m['ch']),
      changePercent: chp.toString(),
      lastUpdate: lastUpdate,
    );
  }
}

class ForexApiService {
  ForexApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // âœ… NEW API ظپظ‚ط·
  static const String _baseUrl =
      'https://api.almurakib.com/conversion-apps/api.php';

  static const String _token = '11x2x2x4x3XXXWWs2a9w8xvVvWxVcJZNuzn9Oft';

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Flutter; Dart)',
      };

  // -------------------------------
  // Helpers
  // -------------------------------

  /// âœ… NEW API: ظ„ط§ط²ظ… symbol ط¨ط¯ظˆظ† "/" ظ…ط«ظ„ EURUSD / XAUUSD / XAGUSD
  String _normalizeSymbol(String symbol) {
    final raw = symbol.trim();
    final upper = raw.toUpperCase();
    return upper.replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// طھط­ط¯ظٹط¯ type ظ„ظ„ظ€ NEW API
  /// - XAU/XAG/XPT/XPD => commodity
  /// - ط؛ظٹط± ظƒط¯ظ‡ => forex
  String _inferType(String symbolNormalized) {
    final s = symbolNormalized.toUpperCase();
    if (s.startsWith('XAU') ||
        s.startsWith('XAG') ||
        s.startsWith('XPT') ||
        s.startsWith('XPD')) {
      return 'commodity';
    }
    return 'forex';
  }

  /// ظٹط®طھط§ط± ط£ظپط¶ظ„ ط¹ظ†طµط± ظ…ظ† response (ظ„ظˆ ظپظٹ ط£ظƒطھط± ظ…ظ† exchange)
  Map<String, dynamic> _pickBestItem(List list) {
    final items =
        list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

    if (items.isEmpty) return <String, dynamic>{};

    // ط­ط§ظˆظ„ طھظپط¶ظ„ FX ط«ظ… FCM ط«ظ… TVC ط«ظ… ط£ظˆظ„ ط¹ظ†طµط±
    final fx = items.firstWhere(
      (m) => (m['ticker']?.toString() ?? '').startsWith('FX:'),
      orElse: () => <String, dynamic>{},
    );
    if (fx.isNotEmpty) return fx;

    final fcm = items.firstWhere(
      (m) => (m['ticker']?.toString() ?? '').startsWith('FCM:'),
      orElse: () => <String, dynamic>{},
    );
    if (fcm.isNotEmpty) return fcm;

    final tvc = items.firstWhere(
      (m) => (m['ticker']?.toString() ?? '').startsWith('TVC:'),
      orElse: () => <String, dynamic>{},
    );
    if (tvc.isNotEmpty) return tvc;

    return items.first;
  }

  Future<Map<String, dynamic>> _getNew({
    required String endpoint,
    required Map<String, String> query,
  }) async {
    final qp = <String, String>{
      'token': _token,
      'endpoint': endpoint,
      ...query,
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: qp);

    if (kDebugMode) {
      // ignore: avoid_print
      print('[NEW API] $uri');
    }

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception(
          'HTTP ${response.statusCode}: ظپط´ظ„ ط§ظ„ط§طھطµط§ظ„ ط¨ط§ظ„ط³ظٹط±ظپط±');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final bool ok = data['status'] == true;
    final int code = int.tryParse(data['code'].toString()) ?? 0;

    if (!ok || code != 200) {
      final msg = data['msg']?.toString() ?? 'Unknown error';
      throw Exception('NEW API error ($code): $msg');
    }

    return data;
  }

  // -------------------------------
  // Public API
  // -------------------------------

  /// âœ… Latest price (NEW API ظپظ‚ط·)
  Future<LatestPrice> getLatestPrice({required String symbol}) async {
    final normalized = _normalizeSymbol(symbol);
    final type = _inferType(normalized);

    final data = await _getNew(
      endpoint: 'latest',
      query: {
        'symbol': normalized,
        'type': type,
      },
    );

    final resp = data['response'];
    if (resp is List && resp.isNotEmpty) {
      final item = _pickBestItem(resp);
      if (item.isNotEmpty) return LatestPrice.fromJson(item);
    }

    throw Exception('ط§ظ„ظ€ API ظ„ظ… طھط±ط¬ط¹ ط¨ظٹط§ظ†ط§طھ ظ„ظ„ط±ظ…ط² $symbol');
  }

  /// âœ… طھط­ظˆظٹظ„ ط¹ظ…ظ„ط© (NEW API ظپظ‚ط·)
  Future<double> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    final f = from.toUpperCase().trim();
    final t = to.toUpperCase().trim();
    if (f == t) return amount;

    final directNew = await _getRatePairNewOrNull('$f$t');
    if (directNew != null) return directNew * amount;

    final inverseNew = await _getRatePairNewOrNull('$t$f');
    if (inverseNew != null && inverseNew != 0) return (1 / inverseNew) * amount;

    throw Exception(
        'ظ„ط§ ظٹظ…ظƒظ† ط§ظ„ط­طµظˆظ„ ط¹ظ„ظ‰ ط³ط¹ط± طھط­ظˆظٹظ„ $from â†’ $to.');
  }

  Future<double?> _getRatePairNewOrNull(String newSymbolNoSlash) async {
    try {
      final data = await _getNew(
        endpoint: 'latest',
        query: {
          'symbol': newSymbolNoSlash.toUpperCase(),
          'type': 'forex',
        },
      );

      final resp = data['response'];
      if (resp is! List || resp.isEmpty) return null;

      final item = _pickBestItem(resp);
      if (item.isEmpty) return null;

      final active = item['active'];
      if (active is! Map) return null;

      final c = active['c'];
      final v = c == null ? null : double.tryParse(c.toString());
      if (v == null || v == 0) return null;
      return v;
    } catch (_) {
      return null;
    }
  }

  /// âœ… History closes (NEW API ظپظ‚ط·)
  /// âœ… ط¥طµظ„ط§ط­: response ظ…ظ…ظƒظ† طھظƒظˆظ† Map (ط²ظٹ ط§ظ„ظ„ظٹ ط¨ط¹طھظ‘ظ‡) ظ…ط´ List
  Future<List<double>> getHistoryCloses({
    required String symbol,
    int days = 10,
  }) async {
    final normalized = _normalizeSymbol(symbol);
    final inferredType = _inferType(normalized);

    // ط¬ط±ظ‘ط¨ ط§ظ„ظ†ظˆط¹ ط§ظ„ظ…طھظˆظ‚ط¹
    final first = await _fetchHistoryCloses(
      symbolNormalized: normalized,
      type: inferredType,
      days: days,
    );
    if (first.isNotEmpty) return first;

    // fallback ط¬ط±ظ‘ط¨ ط§ظ„ظ†ظˆط¹ ط§ظ„طھط§ظ†ظٹ
    final altType = inferredType == 'commodity' ? 'forex' : 'commodity';
    final second = await _fetchHistoryCloses(
      symbolNormalized: normalized,
      type: altType,
      days: days,
    );
    return second;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  double? _extractCloseFromMap(Map<String, dynamic> m) {
    // ظ…ط¨ط§ط´ط± (ط²ظٹ ط§ظ„ظ€ JSON ط¨طھط§ط¹ظƒ: c ظ…ظˆط¬ظˆط¯ط©)
    final direct = _toDouble(m['c'] ?? m['close'] ?? m['cl']);
    if (direct != null) return direct;

    // ط¯ط§ط®ظ„ active
    final active = m['active'];
    if (active is Map) {
      final a = active.cast<String, dynamic>();
      return _toDouble(a['c'] ?? a['close'] ?? a['cl']);
    }

    return null;
  }

  int? _extractTsFromMap(Map<String, dynamic> m, {String? key}) {
    // key ط؛ط§ظ„ط¨ط§ظ‹ ظ‡ظˆ timestamp ظƒظ€ string
    if (key != null) {
      final k = int.tryParse(key);
      if (k != null) return k;
    }
    final t =
        int.tryParse((m['t'] ?? m['time'] ?? m['timestamp'] ?? '').toString());
    return t;
  }

  Future<List<double>> _fetchHistoryCloses({
    required String symbolNormalized,
    required String type,
    required int days,
  }) async {
    final data = await _getNew(
      endpoint: 'history',
      query: {
        'symbol': symbolNormalized,
        'type': type,
        // ط­ط³ط¨ ط§ظ„ظ€ API ط¹ظ†ط¯ظƒ: period 1D ط´ط؛ط§ظ„
        'period': '1D',
        'level': '1',
        // ظ…ظ‡ظ…: ظٹظ‚ظ„ظ„ ط­ط¬ظ… ط§ظ„ط¯ط§طھط§طŒ ظˆظ„ظˆ API طھط¬ط§ظ‡ظ„ظ‡ ظ…ط´ ظ…ط´ظƒظ„ط©
        'length': days.toString(),
        'page': '1',
      },
    );

    dynamic resp = data['response'];

    // âœ… ط§ظ„ط­ط§ظ„ط© ط§ظ„ظ„ظٹ ط¨ط¹طھظ‡ط§: resp = Map(timestamp -> candle)
    if (resp is Map) {
      final entries = resp.entries.toList();

      final points = <MapEntry<int, double>>[];

      for (final e in entries) {
        final key = e.key.toString();
        final val = e.value;

        if (val is Map) {
          final m = val.cast<String, dynamic>();
          final c = _extractCloseFromMap(m);
          final ts = _extractTsFromMap(m, key: key);

          if (c != null && ts != null) {
            points.add(MapEntry(ts, c));
          }
        }
      }

      if (points.isEmpty) {
        if (kDebugMode) {
          // ignore: avoid_print
          print(
              '[HISTORY] Map parsed 0 points for $symbolNormalized type=$type');
        }
        return <double>[];
      }

      // طھط±طھظٹط¨ ط­ط³ط¨ ط§ظ„ط²ظ…ظ†
      points.sort((a, b) => a.key.compareTo(b.key));

      // ط¢ط®ط± days ظ†ظ‚ط§ط·
      final closes = points.map((e) => e.value).toList();
      final out =
          closes.length <= days ? closes : closes.sublist(closes.length - days);

      if (kDebugMode) {
        // ignore: avoid_print
        print(
            '[HISTORY] $symbolNormalized type=$type -> ${out.length} points (Map)');
      }
      return out;
    }

    // âœ… ظ„ظˆ ط±ط¬ط¹ List (ط§ط­طھظ…ط§ظ„ طھط§ظ†ظٹ)
    if (resp is! List || resp.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[HISTORY] empty for $symbolNormalized type=$type');
      }
      return <double>[];
    }

    final closes = <double>[];

    for (final e in resp) {
      if (e is Map) {
        final m = e.cast<String, dynamic>();
        final c = _extractCloseFromMap(m);
        if (c != null) closes.add(c);
      } else if (e is List) {
        // ط¨ط¹ط¶ ط§ظ„ظ€ APIs ط¨طھط±ط¬ط¹ array: [t, o, h, l, c]
        if (e.length >= 5) {
          final c = _toDouble(e[4]);
          if (c != null) closes.add(c);
        } else if (e.length == 2) {
          final c = _toDouble(e[1]);
          if (c != null) closes.add(c);
        }
      }
    }

    if (closes.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(
            '[HISTORY] List parsed 0 closes for $symbolNormalized type=$type');
      }
      return <double>[];
    }

    final out =
        closes.length <= days ? closes : closes.sublist(closes.length - days);

    if (kDebugMode) {
      // ignore: avoid_print
      print(
          '[HISTORY] $symbolNormalized type=$type -> ${out.length} points (List)');
    }

    return out;
  }
}
