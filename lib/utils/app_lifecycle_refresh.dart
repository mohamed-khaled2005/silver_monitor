import 'package:flutter/widgets.dart';

/// Signal عام: أي شاشة ممكن تسمعه (مثلاً: تزود refreshTick للشارت)
class AppLifecycleSignals {
  static final ValueNotifier<int> resumeTick = ValueNotifier<int>(0);

  static void bumpResumeTick() {
    resumeTick.value = resumeTick.value + 1;
  }
}

/// AppLifecycleRefresh
/// - ينفّذ onResumed لما التطبيق يرجع من الخلفية
/// - Anti-spam بـ minInterval
/// - يمنع تكرار التنفيذ لو callback لسه شغال
/// - يطلق AppLifecycleSignals.resumeTick لما يحصل refresh فعلاً
class AppLifecycleRefresh extends StatefulWidget {
  final Widget child;

  /// Callback يتم استدعاؤه عند Resume / Start
  final Future<void> Function(BuildContext context) onResumed;

  /// أقل فترة بين كل refresh و اللي بعده
  final Duration minInterval;

  /// أقل مدة لازم يكون التطبيق قاعد في الخلفية عشان نعمل refresh عند الرجوع
  final Duration minBackgroundDuration;

  /// هل يعمل refresh مرة أول ما يفتح التطبيق (بعد أول frame)
  final bool refreshOnStart;

  /// لو عايز تقفل/تفتح الميزة بشرط (اختياري)
  final bool Function()? enabled;

  const AppLifecycleRefresh({
    super.key,
    required this.child,
    required this.onResumed,
    this.minInterval = const Duration(seconds: 20),
    this.minBackgroundDuration = const Duration(seconds: 2),
    this.refreshOnStart = false,
    this.enabled,
  });

  @override
  State<AppLifecycleRefresh> createState() => _AppLifecycleRefreshState();
}

class _AppLifecycleRefreshState extends State<AppLifecycleRefresh>
    with WidgetsBindingObserver {
  DateTime? _lastRefreshAt;
  DateTime? _backgroundedAt;
  bool _running = false;

  bool _isEnabled() => widget.enabled == null ? true : widget.enabled!();

  bool _passedInterval() {
    final now = DateTime.now();
    if (_lastRefreshAt == null) return true;
    return now.difference(_lastRefreshAt!) >= widget.minInterval;
  }

  bool _passedBackgroundDuration() {
    final now = DateTime.now();
    if (_backgroundedAt == null) return true;
    return now.difference(_backgroundedAt!) >= widget.minBackgroundDuration;
  }

  Future<void> _maybeRefresh({required bool isStart}) async {
    if (!mounted) return;
    if (!_isEnabled()) return;
    if (_running) return;

    if (!_passedInterval()) return;
    if (!isStart && !_passedBackgroundDuration()) return;

    _running = true;
    _lastRefreshAt = DateTime.now();

    bool ran = false;
    try {
      ran = true;
      await widget.onResumed(context);
    } catch (_) {
      // تجاهل
    } finally {
      _running = false;
      if (ran) {
        AppLifecycleSignals.bumpResumeTick();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.refreshOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRefresh(isStart: true);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _maybeRefresh(isStart: false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
