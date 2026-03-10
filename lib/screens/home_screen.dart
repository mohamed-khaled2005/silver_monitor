import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/gold_price_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/top_last_update_banner.dart';
import '../models/currency_model.dart';
import '../models/manual_ad_model.dart';
import 'calculator_screen.dart';
import 'zakat_calculator_screen.dart';
import 'caliber_screen.dart';
import 'bullion_screen.dart';
import 'our_apps_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'account_screen.dart';
import 'educational_content_screen.dart';
import 'profit_loss_screen.dart';
import 'analysis_performance_screen.dart';
import 'support_resistance_screen.dart';
import '../providers/app_manager_provider.dart';
import '../widgets/manual_ad_banner.dart';

// âœ… ADD
import '../utils/first_time_hint.dart';
import '../utils/app_lifecycle_refresh.dart';

/// ًںژ¨ ظ„ظˆظ† ظپط¶ظٹ ظ„ظ„ط§ط³طھط®ط¯ط§ظ… ظپظٹ ظ‡ط°ظ‡ ط§ظ„طµظپط­ط© ط¨ط¯ظ„ط§ظ‹ ظ…ظ† ط§ظ„ط°ظ‡ط¨ظٹ
const Color _silverAccent = Color(0xFFC0C5D5);
const Color _headerSurfaceTop = Color(0xFF13171D);
const Color _headerSurfaceBottom = Color(0xFF0D1015);
const double _headerRowHeight = 38;
const double _headerVerticalPadding = 8;
const double _headerTopPadding = 8;
const double _headerBottomPadding = 11;

class _SideNavItem {
  final int index;
  final String title;
  final IconData icon;
  final String section;

  const _SideNavItem({
    required this.index,
    required this.title,
    required this.icon,
    required this.section,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _homeTabIndex = 0;
  static const int _calculatorTabIndex = 1;
  static const int _zakatTabIndex = 2;
  static const int _calibersTabIndex = 3;
  static const int _bullionsTabIndex = 4;
  static const int _profitLossTabIndex = 5;
  static const int _educationTabIndex = 6;
  static const int _ourAppsTabIndex = 7;
  static const int _aboutTabIndex = 8;
  static const int _contactTabIndex = 9;
  static const int _accountTabIndex = 10;
  static const int _analysisTabIndex = 11;
  static const int _supportResistanceTabIndex = 12;
  static const double _desktopNavBreakpoint = 980;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = _homeTabIndex;

  // âœ… ط¯ظ‡ ط§ظ„ظ„ظٹ ط¨ظٹط±ط¨ط· طھط­ط¯ظٹط« ط§ظ„ط´ط§ط±طھ ط¨ط²ط± ط§ظ„طھط­ط¯ظٹط« / طھط؛ظٹظٹط± ط§ظ„ط¹ظ…ظ„ط©
  int _chartRefreshTick = 0;

  // âœ… Key ظ„ط²ط± ط§ظ„ط±ظٹظپط±ظٹط´ ط¹ط´ط§ظ† ط§ظ„ظ€ spotlight
  final GlobalKey _refreshHintKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  void _onResumeSignal() {
    if (!mounted) return;
    setState(() => _chartRefreshTick++);
  }

  @override
  void initState() {
    super.initState();

    // âœ… ط§ط³ظ…ط¹ signal ط¨طھط§ط¹ resume-refresh
    AppLifecycleSignals.resumeTick.addListener(_onResumeSignal);

    _animationController = AnimationController(
      duration: AppAnimations.pageTransition,
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GoldProvider>(context, listen: false);
      final appManager =
          Provider.of<AppManagerProvider>(context, listen: false);

      final empty = provider.currentGoldPrice == null &&
          provider.calibers.isEmpty &&
          provider.bullions.isEmpty;

      if (empty && !provider.isLoading) {
        provider.initializeData();
      }

      final remoteCurrency = appManager.preferences.selectedCurrency;
      if (remoteCurrency != null &&
          remoteCurrency.isNotEmpty &&
          remoteCurrency != provider.selectedCurrency) {
        provider.setCurrency(remoteCurrency);
      }

      appManager.refreshAd();
      appManager.refreshEducationalContent();

      _animationController.forward();

      // âœ… Hint ظ…ط±ط© ظˆط§ط­ط¯ط© ظپظ‚ط· ط¹ظ„ظ‰ ط²ط± ط§ظ„طھط­ط¯ظٹط«
      FirstTimeHint.showSpotlightHint(
        context: context,
        targetKey: _refreshHintKey,
        prefsKey: 'hint_silver_refresh_button_v1',
        message: 'اضغط هنا لتحديث أسعار الفضة',
        overlayOpacity: 0.35,
        holePadding: 10,
        holeRadius: 16,
        autoDismiss: const Duration(seconds: 10),
      );
    });
  }

  String _ensurePercent(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '0%';
    if (t.contains('%')) return t;
    final d = double.tryParse(t);
    if (d == null) return '$t%';
    final sign = d > 0 ? '+' : '';
    return '$sign${d.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoldProvider>(context);
    final bool isDesktopNav = _isDesktopNav(context);
    final bool isAuthenticated = context.select<AppManagerProvider, bool>(
      (manager) => manager.isAuthenticated,
    );
    final ManualAdModel? activeAd =
        context.select<AppManagerProvider, ManualAdModel?>(
      (manager) => manager.activeAd,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(
        context,
        isDesktopNav: isDesktopNav,
        isAuthenticated: isAuthenticated,
      ),
      drawer: isDesktopNav ? null : _buildSideDrawer(context),
      bottomNavigationBar: ManualAdBanner(
        stickyBottom: true,
        ad: activeAd,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isDesktopNav
            ? Row(
                textDirection: TextDirection.rtl,
                children: [
                  SizedBox(
                    width: 290,
                    child: _buildSideNavigationPanel(closeOnSelect: false),
                  ),
                  Expanded(child: _buildBody(provider)),
                ],
              )
            : _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(GoldProvider provider) {
    final bool hideOurAppsScreen = _shouldHideOurAppsScreen();
    final int effectiveIndex =
        hideOurAppsScreen && _currentIndex == _ourAppsTabIndex
            ? _homeTabIndex
            : _currentIndex;
    final bool showUpdateBanner =
        _shouldShowMarketToolsForIndex(effectiveIndex);

    final bool showFullShimmer = provider.isLoading &&
        effectiveIndex == _homeTabIndex &&
        provider.currentGoldPrice == null;

    final Widget content = showFullShimmer
        ? _buildShimmerLoading()
        : IndexedStack(
            index: effectiveIndex,
            children: [
              _buildHomeContent(provider),
              const CalculatorScreen(),
              const ZakatCalculatorScreen(),
              const CaliberScreen(),
              const BullionScreen(),
              const ProfitLossScreen(),
              const EducationalContentScreen(),
              hideOurAppsScreen
                  ? const SizedBox.shrink()
                  : const OurAppsScreen(),
              const AboutScreen(),
              const ContactScreen(),
              const AccountScreen(),
              AnalysisPerformanceScreen(
                chartRefreshTick: _chartRefreshTick,
                isActive: _currentIndex == _analysisTabIndex,
              ),
              SupportResistanceScreen(
                isActive: _currentIndex == _supportResistanceTabIndex,
              ),
            ],
          );

    final pagePad = Responsive.responsivePadding(context);
    final horizontalPadding = pagePad.horizontal / 2;

    final Widget topBanner = showUpdateBanner
        ? Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_headerSurfaceBottom, _headerSurfaceTop],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: _silverAccent.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: _buildTopUpdateSection(provider, horizontalPadding),
          )
        : const SizedBox.shrink();

    return Column(
      children: [
        topBanner,
        Expanded(child: content),
      ],
    );
  }

  AppBar _buildAppBar(
    BuildContext context, {
    required bool isDesktopNav,
    required bool isAuthenticated,
  }) {
    return AppBar(
      backgroundColor: _headerSurfaceBottom,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight:
          _headerRowHeight + _headerTopPadding + _headerBottomPadding,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_headerSurfaceTop, _headerSurfaceBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            bottom: BorderSide(
              color: _silverAccent.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
      titleSpacing: Responsive.isMobile(context) ? 8 : 16,
      title: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          10,
          _headerTopPadding,
          10,
          _headerBottomPadding,
        ),
        child: SizedBox(
          height: _headerRowHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _openAlmurakibWebsiteFromLogo,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderActionButton(
                    tooltip: 'الرئيسية',
                    onTap: () => _navigateToTab(_homeTabIndex),
                    child: Icon(
                      _currentIndex == _homeTabIndex
                          ? Icons.home_rounded
                          : Icons.home_outlined,
                      color: _silverAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildHeaderActionButton(
                    tooltip: isAuthenticated ? 'حسابي' : 'تسجيل الدخول',
                    onTap: () => _navigateToTab(_accountTabIndex),
                    child: Icon(
                      _currentIndex == _accountTabIndex
                          ? (isAuthenticated
                              ? Icons.person
                              : Icons.account_circle_rounded)
                          : (isAuthenticated
                              ? Icons.person_outline_rounded
                              : Icons.account_circle_outlined),
                      color: _silverAccent,
                    ),
                  ),
                  if (!isDesktopNav) ...[
                    const SizedBox(width: 10),
                    _buildHeaderActionButton(
                      tooltip: '\u0627\u0644\u0642\u0627\u0626\u0645\u0629',
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: _silverAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }

  Widget _buildHeaderActionButton({
    required String tooltip,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _silverAccent.withValues(
                  alpha: onTap == null ? 0.15 : 0.35,
                ),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildTopUpdateSection(
      GoldProvider provider, double horizontalPadding) {
    final currencies = Currency.getCurrencies();
    final currentCurrency = currencies.firstWhere(
      (c) => c.code == provider.selectedCurrency,
      orElse: () => Currency(
        code: provider.selectedCurrency,
        name: provider.selectedCurrency,
        symbol: provider.selectedCurrency,
        flag: '\uD83C\uDFF3\uFE0F',
      ),
    );

    final updateBanner = TopLastUpdateBanner(
      lastUpdatedUtc: provider.currentGoldPrice?.lastUpdated,
    );

    final currencyButton = _buildBannerCurrencyButton(
      currentCurrency: currentCurrency,
      provider: provider,
    );

    final refreshButton = KeyedSubtree(
      key: _refreshHintKey,
      child: _buildUpdateRefreshButton(
        onTap: provider.isLoading
            ? null
            : () {
                setState(() => _chartRefreshTick++);
                provider.setCurrency(provider.selectedCurrency);
              },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: provider.isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(_silverAccent),
                  ),
                )
              : const Icon(
                  key: ValueKey('refresh'),
                  Icons.refresh_rounded,
                  color: _silverAccent,
                  size: 20,
                ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        _headerVerticalPadding,
        horizontalPadding,
        _headerVerticalPadding,
      ),
      child: SizedBox(
        height: _headerRowHeight,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(child: updateBanner),
            const SizedBox(width: 8),
            currencyButton,
            const SizedBox(width: 8),
            refreshButton,
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCurrencyButton({
    required Currency currentCurrency,
    required GoldProvider provider,
  }) {
    return Tooltip(
      message:
          '\u062A\u063A\u064A\u064A\u0631 \u0627\u0644\u0639\u0645\u0644\u0629',
      child: Material(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _showCurrencySelector,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 38,
            width: 108,
            padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 6, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: _silverAccent.withValues(alpha: 0.34),
              ),
              gradient: LinearGradient(
                colors: [
                  _silverAccent.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Text(
                  currentCurrency.flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    provider.selectedCurrency,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: _silverAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateRefreshButton({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: '\u062A\u062D\u062F\u064A\u062B',
      child: Material(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: _silverAccent.withValues(
                  alpha: onTap == null ? 0.20 : 0.40,
                ),
              ),
              gradient: LinearGradient(
                colors: [
                  _silverAccent.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(GoldProvider provider) {
    final price = provider.currentGoldPrice;

    return SingleChildScrollView(
      padding: Responsive.responsivePadding(context),
      child: Column(
        children: [
          if (price == null) ...[
            _emptyState(provider),
          ] else ...[
            GoldPriceCard(
              title: 'سعر أونصة الفضة',
              price: price.ouncePrice.toStringAsFixed(2),
              change: price.change.toStringAsFixed(2),
              changePercent: _ensurePercent(price.changePercent),
              isPositive: price.isPositive,
              currency: provider.selectedCurrency,
            ),
            const SizedBox(height: 16),
            GoldPriceCard(
              title: 'سعر جرام الفضة',
              price: price.gramPrice.toStringAsFixed(2),
              change: (price.change / 31.1035).toStringAsFixed(2),
              changePercent: _ensurePercent(price.changePercent),
              isPositive: price.isPositive,
              currency: provider.selectedCurrency,
            ),
            const SizedBox(height: 10),
            _buildMarketStatusCard(),
            const SizedBox(height: 14),
            _buildLast10DaysTable(
              provider: provider,
              lastUpdated: price.lastUpdated,
            ),
          ],
        ],
      ),
    );
  }

  bool _isSilverMarketOpenNow() {
    final now = DateTime.now();
    return now.weekday != DateTime.saturday && now.weekday != DateTime.sunday;
  }

  Widget _buildMarketStatusCard() {
    final isOpen = _isSilverMarketOpenNow();
    final statusColor = isOpen ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOpen
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                'حالة السوق',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  isOpen ? 'مفتوح' : 'مغلق',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (!isOpen) ...[
            const SizedBox(height: 8),
            Text(
              'سوق التداول وأسعار الفضة تتوقف يومي السبت والأحد.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(GoldProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: _silverAccent, size: 36),
          const SizedBox(height: 12),
          const Text(
            'لا توجد بيانات متاحة حاليا.',
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على زر التحديث لإعادة تحميل أسعار الفضة.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _chartRefreshTick++);
                provider.setCurrency(provider.selectedCurrency);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _silverAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                'تحديث الآن',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// âœ… ط¬ط¯ظˆظ„ ظˆط§ط­ط¯ ظپظ‚ط·: ط§ظ„ط£ط³ط¹ط§ط± ظ„ط¢ط®ط± 10 ط£ظٹط§ظ… (طھط§ط±ظٹط® - ط³ط¹ط±)
  Widget _buildLast10DaysTable({
    required GoldProvider provider,
    required DateTime lastUpdated,
  }) {
    final currency = provider.selectedCurrency;
    final monthlyHistory = provider.chartPricesFor(ChartRange.month);
    final rawHistory = monthlyHistory.length >= 10
        ? monthlyHistory
        : provider.weeklyOuncePrices;
    final trimmedHistory = rawHistory.length <= 10
        ? rawHistory
        : rawHistory.sublist(rawHistory.length - 10);
    final orderedHistory = _ensureHistoryOldestToNewest(
      prices: trimmedHistory,
      latestPrice: provider.currentGoldPrice?.ouncePrice,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الأسعار لآخر 10 أيام',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '($currency)',
                textDirection: TextDirection.ltr,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (trimmedHistory.isEmpty)
            Text(
              'لا توجد بيانات تاريخية الآن.\nاضغط تحديث أو جرّب بعد دقيقة.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )
          else
            _simpleDatePriceTable(
              lastUpdated: lastUpdated,
              prices: orderedHistory,
            ),
        ],
      ),
    );
  }

  List<double> _ensureHistoryOldestToNewest({
    required List<double> prices,
    required double? latestPrice,
  }) {
    if (prices.length < 2 || latestPrice == null) return prices;

    final firstDistance = (prices.first - latestPrice).abs();
    final lastDistance = (prices.last - latestPrice).abs();

    // ط¥ط°ط§ ط£ظ‚ط±ط¨ ظ†ظ‚ط·ط© ظ„ظ„ط³ط¹ط± ط§ظ„ط­ط§ظ„ظٹ ظƒط§ظ†طھ ظپظٹ ط§ظ„ط¨ط¯ط§ظٹط©طŒ ظپط§ظ„ط؛ط§ظ„ط¨ ط£ظ† ط§ظ„طھط±طھظٹط¨ Newestâ†’Oldest.
    if (firstDistance < lastDistance) {
      return prices.reversed.toList();
    }

    return prices;
  }

  // âœ…âœ… ط§ظ„ظ…ط·ظ„ظˆط¨: ط§ظ„طھط§ط±ظٹط® ط£ظ‚طµظ‰ ظٹظ…ظٹظ† (Right Edge) ظˆط§ظ„ط³ط¹ط± ط£ظ‚طµظ‰ ط´ظ…ط§ظ„ (Left Edge)
  Widget _simpleDatePriceTable({
    required DateTime lastUpdated,
    required List<double> prices,
  }) {
    final headerStyle = AppTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w900,
      color: AppColors.textSecondary,
    );

    final cellStyle = AppTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    );

    final dividerColor = Colors.white.withAlpha((0.08 * 255).toInt());
    final rowDividerColor = Colors.white.withAlpha((0.06 * 255).toInt());

    final n = prices.length;

    String fmtDate(DateTime d) =>
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

    DateTime dateForIndex(int i) {
      final daysBack = (n - 1) - i;
      final localLastUpdated = lastUpdated.toLocal();
      final base = DateTime(
        localLastUpdated.year,
        localLastUpdated.month,
        localLastUpdated.day,
      );
      return base.subtract(Duration(days: daysBack));
    }

    Widget rowItem({
      required Widget leftPrice,
      required Widget rightDate,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(flex: 2, child: leftPrice),
              VerticalDivider(
                width: 22,
                thickness: 1,
                color: dividerColor,
              ),
              Expanded(flex: 3, child: rightDate),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha((0.22 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          // âœ… Header
          rowItem(
            leftPrice: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'السعر',
                style: headerStyle,
                textAlign: TextAlign.left,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            rightDate: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'التاريخ',
                style: headerStyle,
                textAlign: TextAlign.right,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Divider(height: 1, color: dividerColor),

          // âœ… Rows
          for (int i = prices.length - 1; i >= 0; i--) ...[
            Container(
              color: (prices.length - 1 - i).isEven
                  ? Colors.transparent
                  : AppColors.cardDark.withAlpha((0.10 * 255).toInt()),
              child: rowItem(
                leftPrice: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    prices[i].toStringAsFixed(2),
                    style: cellStyle,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                rightDate: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    fmtDate(dateForIndex(i)),
                    style: cellStyle,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (i != 0) Divider(height: 1, color: rowDividerColor),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: Responsive.responsivePadding(context),
      child: Column(
        children: [
          ShimmerLoading(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ShimmerLoading(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ShimmerLoading(
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDesktopNav(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopNavBreakpoint;
  }

  Drawer _buildSideDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 380 ? 320.0 : screenWidth * 0.86;

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildSideNavigationPanel(closeOnSelect: true),
    );
  }

  Widget _buildSideNavigationPanel({required bool closeOnSelect}) {
    final items = _navigationItems(hideOurApps: _shouldHideOurAppsScreen());
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1116), Color(0xFF161A22), Color(0xFF1A1F29)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: Colors.white10, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final bool isSelected = _currentIndex == item.index;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: AppAnimations.buttonAnimation,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0x2EC0C5D5), Color(0x14474D5C)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? _silverAccent.withValues(alpha: 0.38)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _navigateToTab(
                        item.index,
                        closeDrawer: closeOnSelect,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsetsDirectional.fromSTEB(
                          12,
                          6,
                          10,
                          6,
                        ),
                        leading: Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? _silverAccent
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          item.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_SideNavItem> _navigationItems({required bool hideOurApps}) {
    return [
      const _SideNavItem(
        index: _homeTabIndex,
        title: 'الصفحة الرئيسية',
        icon: Icons.home_outlined,
        section: 'القائمة الرئيسية',
      ),
      const _SideNavItem(
        index: _analysisTabIndex,
        title: 'تحليل وأداء الفضة',
        icon: Icons.analytics_outlined,
        section: 'الأسعار والتحليل',
      ),
      const _SideNavItem(
        index: _supportResistanceTabIndex,
        title: 'الدعم والمقاومة',
        icon: Icons.layers_outlined,
        section: 'الأسعار والتحليل',
      ),
      const _SideNavItem(
        index: _calibersTabIndex,
        title: 'أسعار العيارات',
        icon: Icons.diamond_outlined,
        section: 'الأسعار والتحليل',
      ),
      const _SideNavItem(
        index: _bullionsTabIndex,
        title: 'أسعار السبائك',
        icon: Icons.auto_awesome_outlined,
        section: 'الأسعار والتحليل',
      ),
      const _SideNavItem(
        index: _calculatorTabIndex,
        title: 'حاسبة سعر الفضة',
        icon: Icons.calculate_outlined,
        section: 'الحاسبات',
      ),
      const _SideNavItem(
        index: _profitLossTabIndex,
        title: 'حاسبة الربح والخسارة',
        icon: Icons.trending_up_rounded,
        section: 'الحاسبات',
      ),
      const _SideNavItem(
        index: _zakatTabIndex,
        title: 'حاسبة زكاة الفضة',
        icon: Icons.mosque_outlined,
        section: 'الحاسبات',
      ),
      const _SideNavItem(
        index: _educationTabIndex,
        title: 'المحتوى التعليمي',
        icon: Icons.menu_book_outlined,
        section: 'المحتوى والمعلومات',
      ),
      if (!hideOurApps)
        const _SideNavItem(
          index: _ourAppsTabIndex,
          title: 'تطبيقاتنا',
          icon: Icons.apps_outlined,
          section: 'المحتوى والمعلومات',
        ),
      const _SideNavItem(
        index: _aboutTabIndex,
        title: 'عن التطبيق',
        icon: Icons.info_outline_rounded,
        section: 'المحتوى والمعلومات',
      ),
      const _SideNavItem(
        index: _contactTabIndex,
        title: 'الاتصال بنا',
        icon: Icons.contact_page_outlined,
        section: 'المحتوى والمعلومات',
      ),
    ];
  }

  void _navigateToTab(int index, {bool closeDrawer = false}) {
    if (_shouldHideOurAppsScreen() && index == _ourAppsTabIndex) {
      index = _homeTabIndex;
    }

    if (closeDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    final appManager = Provider.of<AppManagerProvider>(context, listen: false);
    appManager.trackPageView(_trackingNameForTab(index));
  }

  String _trackingNameForTab(int index) {
    switch (index) {
      case _homeTabIndex:
        return 'home';
      case _calculatorTabIndex:
        return 'silver_calculator';
      case _zakatTabIndex:
        return 'zakat_calculator';
      case _calibersTabIndex:
        return 'calibers';
      case _bullionsTabIndex:
        return 'bullions';
      case _profitLossTabIndex:
        return 'profit_loss';
      case _educationTabIndex:
        return 'education';
      case _ourAppsTabIndex:
        return 'our_apps';
      case _aboutTabIndex:
        return 'about';
      case _contactTabIndex:
        return 'contact';
      case _accountTabIndex:
        return 'account';
      case _analysisTabIndex:
        return 'analysis_performance';
      case _supportResistanceTabIndex:
        return 'support_resistance';
      default:
        return 'tab_$index';
    }
  }

  bool _shouldHideOurAppsScreen() {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool _shouldShowMarketToolsForIndex(int index) {
    return index == _homeTabIndex ||
        index == _analysisTabIndex ||
        index == _supportResistanceTabIndex ||
        index == _calculatorTabIndex ||
        index == _zakatTabIndex ||
        index == _calibersTabIndex ||
        index == _bullionsTabIndex;
  }

  Future<void> _openAlmurakibWebsiteFromLogo() async {
    final bool? shouldOpen = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _silverAccent.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          title: Text(
            'زيارة موقع المراقب؟',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          content: Text(
            'هل تريد فتح موقع المراقب الآن؟',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _silverAccent,
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'فتح الموقع',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true || !mounted) return;

    final Uri uri = Uri.parse('https://almurakib.com/');
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط الآن')),
      );
    }
  }

  Future<void> _showCurrencySelector() async {
    final provider = context.read<GoldProvider>();
    final allCurrencies = Currency.getCurrencies();

    final selected = await showModalBottomSheet<Currency>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CurrencySelectorSheet(
        allCurrencies: allCurrencies,
        selectedCurrencyCode: provider.selectedCurrency,
      ),
    );

    if (!mounted || selected == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency_code', selected.code);

    if (!mounted) return;

    setState(() => _chartRefreshTick++);
    provider.setCurrency(selected.code);
    context.read<AppManagerProvider>().setSelectedCurrency(selected.code);
  }

  @override
  void dispose() {
    AppLifecycleSignals.resumeTick.removeListener(_onResumeSignal);
    _animationController.dispose();
    super.dispose();
  }
}

class _CurrencySelectorSheet extends StatefulWidget {
  const _CurrencySelectorSheet({
    required this.allCurrencies,
    required this.selectedCurrencyCode,
  });

  final List<Currency> allCurrencies;
  final String selectedCurrencyCode;

  @override
  State<_CurrencySelectorSheet> createState() => _CurrencySelectorSheetState();
}

class _CurrencySelectorSheetState extends State<_CurrencySelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetMaxHeight = mediaQuery.size.height * 0.82;
    final q = _searchController.text.trim().toLowerCase();

    final filtered = q.isEmpty
        ? widget.allCurrencies
        : widget.allCurrencies.where((c) {
            return c.code.toLowerCase().contains(q) ||
                c.name.toLowerCase().contains(q);
          }).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: mediaQuery.viewInsets.bottom + 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: sheetMaxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'تغيير العملة',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                keyboardAppearance: Brightness.dark,
                cursorColor: _silverAccent,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الرمز (مثال: SAR / ريال)',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.search, color: _silverAccent),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ظ…ط³ط­',
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            FocusScope.of(context).requestFocus(_focusNode);
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _silverAccent.withValues(alpha: 0.65),
                      width: 1.1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'ظ„ط§ طھظˆط¬ط¯ ظ†طھط§ط¦ط¬ ظ…ط·ط§ط¨ظ‚ط©',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: Colors.white12,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final currency = filtered[index];
                          final isSelected =
                              currency.code == widget.selectedCurrencyCode;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.of(context).pop(currency),
                              child: SizedBox(
                                height: 54,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: Center(
                                        child: Text(
                                          currency.flag,
                                          textAlign: TextAlign.center,
                                          strutStyle: const StrutStyle(
                                            forceStrutHeight: true,
                                            height: 1,
                                            leading: 0,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currency.name,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: AppColors.textPrimary,
                                              fontSize: 12.8,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            currency.code,
                                            textDirection: TextDirection.ltr,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: _silverAccent,
                                            size: 18,
                                          )
                                        : const Icon(
                                            Icons.chevron_right,
                                            color: AppColors.textSecondary,
                                            size: 18,
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
