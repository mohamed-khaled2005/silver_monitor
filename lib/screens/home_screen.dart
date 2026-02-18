import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/gold_price_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/top_last_update_banner.dart';
import '../models/currency_model.dart';
import 'calculator_screen.dart';
import 'caliber_screen.dart';
import 'bullion_screen.dart';
import 'our_apps_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';

// ✅ ADD
import '../utils/first_time_hint.dart';
import '../utils/app_lifecycle_refresh.dart';

/// 🎨 لون فضي للاستخدام في هذه الصفحة بدلاً من الذهبي
const Color _silverAccent = Color(0xFFC0C5D5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // ✅ ده اللي بيربط تحديث الشارت بزر التحديث / تغيير العملة
  int _chartRefreshTick = 0;

  // ✅ Key لزر الريفريش عشان الـ spotlight
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

    // ✅ اسمع signal بتاع resume-refresh
    AppLifecycleSignals.resumeTick.addListener(_onResumeSignal);

    _animationController = AnimationController(
      duration: AppAnimations.pageTransition,
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GoldProvider>(context, listen: false);

      final empty = provider.currentGoldPrice == null &&
          provider.calibers.isEmpty &&
          provider.bullions.isEmpty;

      if (empty && !provider.isLoading) {
        provider.initializeData();
      }

      _animationController.forward();

      // ✅ Hint مرة واحدة فقط على زر التحديث
      FirstTimeHint.showSpotlightHint(
        context: context,
        targetKey: _refreshHintKey,
        prefsKey: 'hint_silver_refresh_button_v1',
        message: 'اضغط هنا لتحديث أسعار الفضة (مرة واحدة فقط)',
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, provider),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(provider),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildBody(GoldProvider provider) {
    final bool showUpdateBanner = _currentIndex <= 3;

    final bool showFullShimmer = provider.isLoading &&
        _currentIndex == 0 &&
        provider.currentGoldPrice == null;

    final Widget content = showFullShimmer
        ? _buildShimmerLoading()
        : IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(provider),
              CalculatorScreen(),
              CaliberScreen(),
              BullionScreen(),
              OurAppsScreen(),
              AboutScreen(),
              ContactScreen(),
            ],
          );

    final pagePad = Responsive.responsivePadding(context);
    final horizontalPadding = pagePad.horizontal / 2;

    final Widget topBanner = showUpdateBanner
        ? Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              2,
            ),
            child: TopLastUpdateBanner(
              lastUpdatedUtc: provider.currentGoldPrice?.lastUpdated,
              isLoading: provider.isLoading,
            ),
          )
        : const SizedBox.shrink();

    return Column(
      children: [
        topBanner,
        Expanded(child: content),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, GoldProvider provider) {
    final currencies = Currency.getCurrencies();
    final currentCurrency = currencies.firstWhere(
      (c) => c.code == provider.selectedCurrency,
      orElse: () => Currency(
        code: provider.selectedCurrency,
        name: provider.selectedCurrency,
        symbol: provider.selectedCurrency,
        flag: '🏳️',
      ),
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      titleSpacing: Responsive.isMobile(context) ? 8 : 16,
      title: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12.0),
        child: SizedBox(
          height: 40,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _openAlmurakibWebsiteFromLogo,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 4.0),
          child: SizedBox(
            height: 36,
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _showCurrencySelector,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _silverAccent.withAlpha((0.50 * 255).toInt()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(currentCurrency.flag,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          provider.selectedCurrency,
                          style: const TextStyle(
                            color: _silverAccent,
                            fontSize: 12,
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Padding(
                        padding: EdgeInsets.only(top: 1.0),
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: _silverAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ✅ زر التحديث + Hint
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: KeyedSubtree(
            key: _refreshHintKey,
            child: IconButton(
              onPressed: provider.isLoading
                  ? null
                  : () {
                      setState(() => _chartRefreshTick++);
                      provider.setCurrency(provider.selectedCurrency);
                    },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: provider.isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _silverAccent,
                          ),
                        ),
                      )
                    : const Icon(
                        key: ValueKey('icon'),
                        Icons.refresh,
                        color: _silverAccent,
                      ),
              ),
              tooltip: 'تحديث الأسعار',
            ),
          ),
        ),
      ],
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'آخر تحديث: ${_formatLastUpdated(price.lastUpdated)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceChart(),
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
          Text(
            'لا توجد بيانات متاحة حالياً',
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
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

  /// ✅ جدول واحد فقط: الأسعار لآخر 10 أيام (تاريخ - سعر)
  Widget _buildLast10DaysTable({
    required GoldProvider provider,
    required DateTime lastUpdated,
  }) {
    final currency = provider.selectedCurrency;
    final history = provider.weeklyOuncePrices;
    final trimmedHistory =
        history.length <= 10 ? history : history.sublist(history.length - 10);
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
          if (history.isEmpty)
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

    // إذا أقرب نقطة للسعر الحالي كانت في البداية، فالغالب أن الترتيب Newest→Oldest.
    if (firstDistance < lastDistance) {
      return prices.reversed.toList();
    }

    return prices;
  }

  // ✅✅ المطلوب: التاريخ أقصى يمين (Right Edge) والسعر أقصى شمال (Left Edge)
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

    Widget _row({
      required Widget leftPrice, // ✅ أقصى الشمال
      required Widget rightDate, // ✅ أقصى اليمين
    }) {
      return Padding(
        // تقدر تقللها لو عايز أقرب للحافة
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: IntrinsicHeight(
          child: Row(
            // ✅ LTR عشان أول عنصر يبقى أقصى يسار وآخر عنصر أقصى يمين
            textDirection: TextDirection.ltr,
            children: [
              Expanded(flex: 2, child: leftPrice), // ✅ يسار: السعر
              VerticalDivider(
                width: 22,
                thickness: 1,
                color: dividerColor,
              ),
              Expanded(flex: 3, child: rightDate), // ✅ يمين: التاريخ
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
          // ✅ Header
          _row(
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

          // ✅ Rows
          for (int i = prices.length - 1; i >= 0; i--) ...[
            Container(
              color: (prices.length - 1 - i).isEven
                  ? Colors.transparent
                  : AppColors.cardDark.withAlpha((0.10 * 255).toInt()),
              child: _row(
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

  String _formatLastUpdated(DateTime time) {
    final local = time.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs();
    final minutes = offset.inMinutes.abs() % 60;
    final gmt = minutes == 0
        ? 'GMT$sign$hours'
        : 'GMT$sign$hours:${minutes.toString().padLeft(2, '0')}';

    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} ($gmt)';
  }

  Widget _buildPriceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حركة السعر لآخر 10 أيام',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PriceChart(refreshTick: _chartRefreshTick),
          ),
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
    final provider = Provider.of<GoldProvider>(context, listen: false);
    final allCurrencies = Currency.getCurrencies();

    final searchController = TextEditingController();
    final focusNode = FocusNode();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final q = searchController.text.trim().toLowerCase();

                final filtered = q.isEmpty
                    ? allCurrencies
                    : allCurrencies.where((c) {
                        return c.code.toLowerCase().contains(q) ||
                            c.name.toLowerCase().contains(q);
                      }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.18 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('تغيير العملة', style: AppTextStyles.headingMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      keyboardAppearance: Brightness.dark,
                      cursorColor: _silverAccent,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو الرمز (مثال: SAR / ريال)',
                        hintStyle: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: _silverAccent),
                        suffixIcon: q.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح',
                                icon: const Icon(Icons.close,
                                    color: AppColors.textSecondary, size: 20),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() {});
                                  FocusScope.of(context)
                                      .requestFocus(focusNode);
                                },
                              ),
                        filled: true,
                        fillColor: AppColors.background
                            .withAlpha((0.55 * 255).toInt()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha((0.08 * 255).toInt()),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withAlpha((0.08 * 255).toInt()),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color:
                                _silverAccent.withAlpha((0.65 * 255).toInt()),
                            width: 1.1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              child: Text(
                                'لا توجد نتائج مطابقة',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: Colors.white12,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final currency = filtered[index];
                                final isSelected =
                                    currency.code == provider.selectedCurrency;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(currency.flag,
                                      style: const TextStyle(fontSize: 22)),
                                  title: Text(
                                    currency.name,
                                    style: AppTextStyles.bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    currency.code,
                                    textDirection: TextDirection.ltr,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle,
                                          color: _silverAccent)
                                      : const Icon(Icons.chevron_right,
                                          color: AppColors.textSecondary),
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      'selected_currency_code',
                                      currency.code,
                                    );

                                    if (mounted) {
                                      setState(() => _chartRefreshTick++);
                                    }
                                    provider.setCurrency(currency.code);

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    searchController.dispose();
    focusNode.dispose();
  }

  @override
  void dispose() {
    AppLifecycleSignals.resumeTick.removeListener(_onResumeSignal);
    _animationController.dispose();
    super.dispose();
  }
}
