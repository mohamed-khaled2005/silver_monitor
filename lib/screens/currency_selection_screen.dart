import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency_model.dart';
import '../providers/app_manager_provider.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';

/// 🎨 لون فضي (زي HomeScreen)
const Color _silverAccent = Color(0xFFC0C5D5);

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({Key? key}) : super(key: key);

  @override
  State<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _searchQuery = '';
  String? _selectedCode;

  late final List<Currency> _allCurrencies;
  late final List<_IndexedCurrency> _indexed;

  final ValueNotifier<List<_IndexedCurrency>> _filteredNotifier =
      ValueNotifier<List<_IndexedCurrency>>([]);

  @override
  void initState() {
    super.initState();

    final provider = Provider.of<GoldProvider>(context, listen: false);
    _selectedCode = provider.selectedCurrency;

    _allCurrencies = Currency.getCurrencies();
    _indexed = _allCurrencies
        .map((c) => _IndexedCurrency(
              currency: c,
              codeLower: c.code.toLowerCase(),
              nameLower: c.name.toLowerCase(),
            ))
        .toList();

    _filteredNotifier.value = List<_IndexedCurrency>.from(_indexed);

    // ✅ تحديث الفلترة + تحديث زر المسح (suffix) بشكل صحيح
    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q == _searchQuery) return;

      setState(() => _searchQuery = q);
      _applyFilter(q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _filteredNotifier.dispose();
    super.dispose();
  }

  void _applyFilter(String q) {
    final query = q.toLowerCase();
    if (query.isEmpty) {
      _filteredNotifier.value = List<_IndexedCurrency>.from(_indexed);
      return;
    }

    final out = <_IndexedCurrency>[];
    for (final item in _indexed) {
      if (item.codeLower.contains(query) || item.nameLower.contains(query)) {
        out.add(item);
      }
    }
    _filteredNotifier.value = out;
  }

  Future<void> _confirmSelection() async {
    if (_selectedCode == null || _selectedCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك اختر عملة أولاً')),
      );
      return;
    }

    final code = _selectedCode!;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency_code', code);

    final provider = Provider.of<GoldProvider>(context, listen: false);
    provider.setCurrency(code);
    final appManager = Provider.of<AppManagerProvider>(context, listen: false);
    appManager.setSelectedCurrency(code);

    if (!mounted) return;

    // ✅ لو جاي من داخل التطبيق ارجع
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, code);
      return;
    }

    // ✅ لو أول شاشة
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.responsivePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,

      // ✅ صفحة عادية (Full Screen) مش Popup
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'اختيار العملة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
            color: _silverAccent,
          ),
        ),
        iconTheme: const IconThemeData(color: _silverAccent),
      ),

      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: padding.left,
            right: padding.right,
            top: padding.top,
            bottom: MediaQuery.of(context).viewInsets.bottom + padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر عملتك المفضلة لعرض أسعار الفضة:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),

              // ✅ نفس تصميم البحث + إصلاح لون النص
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                keyboardAppearance: Brightness.dark,
                cursorColor: _silverAccent,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white, // ✅ بدل الأسود
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الرمز (مثال: SAR / ريال)',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.search, color: _silverAccent),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح',
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter('');
                            FocusScope.of(context).requestFocus(_focusNode);
                          },
                        ),
                  filled: true,
                  fillColor:
                      AppColors.background.withAlpha((0.55 * 255).toInt()),
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
                      color: _silverAccent.withAlpha((0.65 * 255).toInt()),
                      width: 1.1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.06 * 255).toInt()),
                    ),
                  ),
                  child: ValueListenableBuilder<List<_IndexedCurrency>>(
                    valueListenable: _filteredNotifier,
                    builder: (context, filtered, _) {
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد نتائج مطابقة',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: Colors.white12,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final currency = filtered[index].currency;
                          final isSelected = currency.code == _selectedCode;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text(
                              currency.flag,
                              style: const TextStyle(fontSize: 22),
                            ),
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
                                ? const Icon(
                                    Icons.check_circle,
                                    color: _silverAccent,
                                  )
                                : const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                  ),
                            onTap: () => setState(() {
                              _selectedCode = currency.code;
                            }),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ زر متابعة (ستايل فضة)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _silverAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'متابعة',
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
        ),
      ),
    );
  }
}

class _IndexedCurrency {
  final Currency currency;
  final String codeLower;
  final String nameLower;

  _IndexedCurrency({
    required this.currency,
    required this.codeLower,
    required this.nameLower,
  });
}
