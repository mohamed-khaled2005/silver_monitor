import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_manager_provider.dart';
import '../providers/gold_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/app_section_header.dart';
import 'auth_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const Color _silverAccent = Color(0xFFC0C5D5);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _openAuth() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const AuthScreen()),
    );
    if (result == true && mounted) {
      final manager = context.read<AppManagerProvider>();
      final selected = manager.preferences.selectedCurrency;
      if (selected != null && selected.isNotEmpty) {
        context.read<GoldProvider>().setCurrency(selected);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح.')),
      );
    }
  }

  Future<void> _saveProfile(AppManagerProvider manager) async {
    final user = manager.user;
    final canChangePassword = user?.hasPassword == true;

    final ok = await manager.updateProfile(
      fullName: _nameController.text.trim(),
      currentPassword:
          canChangePassword && _currentPasswordController.text.trim().isNotEmpty
              ? _currentPasswordController.text.trim()
              : null,
      newPassword:
          canChangePassword && _newPasswordController.text.trim().isNotEmpty
              ? _newPasswordController.text.trim()
              : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'تم تحديث الحساب.'
              : (manager.errorMessage ?? 'فشل تحديث الحساب.'),
        ),
      ),
    );

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
    }
  }

  Future<void> _logoutAndRequireAuth(AppManagerProvider manager) async {
    await manager.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(
          redirectToHomeOnSuccess: true,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _confirmDelete(AppManagerProvider manager) async {
    final user = manager.user;
    if (user == null) return;

    String? password;
    bool shouldDelete = false;

    if (user.hasPassword) {
      final passController = TextEditingController();
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.30),
              ),
            ),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error.withValues(alpha: 0.95),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تأكيد حذف الحساب',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    'سيتم حذف الحساب نهائيا. أدخل كلمة المرور للتأكيد.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInputField(
                  controller: passController,
                  label: 'كلمة المرور',
                  obscureText: true,
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  textStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('تأكيد الحذف'),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        passController.dispose();
        return;
      }
      shouldDelete = dialogResult == true;
      password = passController.text.trim();
      passController.dispose();

      if (shouldDelete && password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل كلمة المرور أولا.')),
        );
        return;
      }
    } else {
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.30),
              ),
            ),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error.withValues(alpha: 0.95),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تأكيد حذف الحساب',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.30),
                ),
              ),
              child: Text(
                'سيتم حذف حسابك نهائيا. هل تريد المتابعة؟',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  textStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('تأكيد الحذف'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      shouldDelete = dialogResult == true;
    }

    if (!shouldDelete) return;

    final ok = await manager.deleteAccount(password: password);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم حذف الحساب.' : (manager.errorMessage ?? 'فشل حذف الحساب.'),
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: '...',
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontFamily: 'Tajawal',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _silverAccent),
      ),
    );
  }

  Widget _labeledInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
          ),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _silverAccent),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _favoriteIconForKey(String key) {
    if (key.startsWith('caliber:')) return Icons.workspace_premium_rounded;
    if (key.startsWith('bullion:')) return Icons.inventory_2_rounded;
    return Icons.favorite_rounded;
  }

  String _favoriteLabel(String key) {
    if (key.startsWith('caliber:')) {
      final value = key.substring('caliber:'.length).trim();
      return value.isEmpty ? 'عيار' : 'عيار $value';
    }
    if (key.startsWith('bullion:')) {
      final value = key.substring('bullion:'.length).trim();
      return value.isEmpty ? 'سبيكة' : value;
    }
    return key;
  }

  Widget _buildFavoriteChip(AppManagerProvider manager, String key) {
    return InputChip(
      avatar: Icon(
        _favoriteIconForKey(key),
        size: 16,
        color: _silverAccent,
      ),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 170),
        child: Text(
          _favoriteLabel(key),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onDeleted: manager.isBusy ? null : () => manager.toggleFavoriteItem(key),
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
      deleteIconColor: AppColors.textSecondary,
    );
  }

  Widget _buildFavoritesCard({
    required AppManagerProvider manager,
    required List<String> favorites,
    required bool showDeleteAccount,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'المفضلة المحفوظة (${favorites.length})',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            Text(
              'لا توجد عناصر مفضلة محفوظة حاليا.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Text(
              'اضغط على × لإزالة أي عنصر من المفضلة.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  favorites.map((key) => _buildFavoriteChip(manager, key)).toList(),
            ),
          ],
          if (!manager.isAuthenticated) ...[
            const SizedBox(height: 10),
            Text(
              'سجل الدخول لمزامنة المفضلة بين أجهزتك.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (showDeleteAccount) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: manager.isBusy ? null : () => _confirmDelete(manager),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade300,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('حذف الحساب'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();
    final user = manager.user;
    final pagePadding = Responsive.responsivePadding(context);
    final favorites = List<String>.from(manager.preferences.favoriteItems)
      ..sort((a, b) => _favoriteLabel(a).compareTo(_favoriteLabel(b)));

    if (user == null) {
      return SingleChildScrollView(
        padding: pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 6),
            const AppSectionHeader(title: 'حسابي'),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _silverAccent.withValues(alpha: 0.16),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: _silverAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'سجل الدخول لحفظ المفضلة والعملة ومزامنة إعداداتك بين الأجهزة.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _openAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _silverAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'تسجيل الدخول / إنشاء حساب',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildFavoritesCard(
              manager: manager,
              favorites: favorites,
              showDeleteAccount: false,
            ),
          ],
        ),
      );
    }

    final fullName = user.fullName ?? '';
    if (_nameController.text != fullName) {
      _nameController.text = fullName;
    }

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 6),
          const AppSectionHeader(title: 'حسابي'),
          const SizedBox(height: 16),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _silverAccent.withValues(alpha: 0.16),
                      ),
                      child: const Icon(
                        Icons.account_circle_rounded,
                        color: _silverAccent,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.email,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.verified_user_outlined,
                      text: 'النوع: ${user.authProvider}',
                    ),
                    _buildInfoChip(
                      icon: Icons.info_outline_rounded,
                      text: 'الحالة: ${user.status}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'تعديل البيانات',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _labeledInputField(
                  controller: _nameController,
                  label: 'الاسم',
                ),
                if (user.hasPassword) ...<Widget>[
                  const SizedBox(height: 10),
                  _labeledInputField(
                    controller: _currentPasswordController,
                    label: 'كلمة المرور الحالية',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  _labeledInputField(
                    controller: _newPasswordController,
                    label: 'كلمة المرور الجديدة',
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: manager.isBusy
                              ? null
                              : () => _saveProfile(manager),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _silverAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'حفظ التعديلات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: manager.isBusy
                              ? null
                              : () => _logoutAndRequireAuth(manager),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                AppColors.cardLight.withValues(alpha: 0.40),
                            foregroundColor:
                                AppColors.error.withValues(alpha: 0.92),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.42),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFavoritesCard(
            manager: manager,
            favorites: favorites,
            showDeleteAccount: true,
          ),
        ],
      ),
    );
  }
}


