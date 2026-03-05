import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_manager_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

const Color _silverAccent = Color(0xFFC0C5D5);
const Color _authTop = Color(0xFF0A0A0A);
const Color _authBottom = Color(0xFF050505);
const Color _authSurface = Color(0xFF151515);
const Color _authInput = Color(0xFF101010);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    Key? key,
    this.redirectToHomeOnSuccess = false,
  }) : super(key: key);

  final bool redirectToHomeOnSuccess;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _fullName = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    final manager = context.read<AppManagerProvider>();

    final ok = _isRegisterMode
        ? await manager.register(
            email: _email.text,
            password: _password.text,
            fullName: _fullName.text,
          )
        : await manager.login(
            email: _email.text,
            password: _password.text,
          );

    if (!mounted) return;
    if (ok) {
      await _handleSuccess();
      return;
    }

    _showError(manager.errorMessage ?? 'حدث خطأ أثناء العملية.');
  }

  Future<void> _loginWithGoogle() async {
    final manager = context.read<AppManagerProvider>();
    final ok = await manager.loginWithGoogle();
    if (!mounted) return;
    if (ok) {
      await _handleSuccess();
      return;
    }
    _showError(manager.errorMessage ?? 'تعذر تسجيل الدخول عبر Google.');
  }

  Future<void> _loginWithApple() async {
    final manager = context.read<AppManagerProvider>();
    final ok = await manager.loginWithApple();
    if (!mounted) return;
    if (ok) {
      await _handleSuccess();
      return;
    }
    _showError(manager.errorMessage ?? 'تعذر تسجيل الدخول عبر Apple.');
  }

  Future<void> _handleSuccess() async {
    if (!mounted) return;
    if (widget.redirectToHomeOnSuccess) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  void _continueWithoutLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppManagerProvider>();
    final canUseApple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return PopScope(
      canPop: !widget.redirectToHomeOnSuccess,
      child: Scaffold(
        backgroundColor: _authBottom,
        body: Stack(
          children: [
            const _AuthBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: widget.redirectToHomeOnSuccess
                              ? TextButton.icon(
                                  onPressed: manager.isBusy
                                      ? null
                                      : _continueWithoutLogin,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _silverAccent,
                                  ),
                                  icon: const Icon(
                                    Icons.home_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'تخطي الدخول',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: manager.isBusy
                                      ? null
                                      : () => Navigator.maybePop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.textPrimary,
                                    size: 18,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        _buildHero(),
                        const SizedBox(height: 16),
                        _buildAuthCard(
                          manager: manager,
                          canUseApple: canUseApple,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'بالاستمرار أنت توافق على شروط الاستخدام وسياسة الخصوصية.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.78),
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final title = _isRegisterMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول';
    final description = _isRegisterMode
        ? 'أنشئ حسابا جديدا لحفظ بياناتك ومزامنة إعداداتك على جميع أجهزتك.'
        : 'سجّل دخولك للوصول إلى بياناتك ومزامنة إعداداتك على جميع أجهزتك.';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _authSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _silverAccent.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: _silverAccent.withValues(alpha: 0.30),
              ),
            ),
            child: Image.asset(
              'assets/images/Icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard({
    required AppManagerProvider manager,
    required bool canUseApple,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: _authSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _silverAccent.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSwitcher(),
            const SizedBox(height: 14),
            _buildSocialButtons(
              busy: manager.isBusy,
              canUseApple: canUseApple,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: _silverAccent.withValues(alpha: 0.18),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'أو بالبريد الإلكتروني',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: _silverAccent.withValues(alpha: 0.18),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isRegisterMode) ...[
              TextFormField(
                controller: _fullName,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'الاسم الكامل',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) {
                  final input = (value ?? '').trim();
                  if (input.isEmpty) return null;
                  if (input.length < 3) {
                    return 'اكتب اسما واضحا لا يقل عن 3 أحرف.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                label: 'البريد الإلكتروني',
                icon: Icons.alternate_email_rounded,
              ),
              validator: (value) {
                final input = (value ?? '').trim();
                if (input.isEmpty) {
                  return 'أدخل البريد الإلكتروني.';
                }
                if (!input.contains('@') || !input.contains('.')) {
                  return 'صيغة البريد الإلكتروني غير صحيحة.';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitEmailAuth(),
              decoration: _fieldDecoration(
                label: 'كلمة المرور',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                final input = value ?? '';
                if (input.isEmpty) {
                  return 'أدخل كلمة المرور.';
                }
                if (input.length < 8) {
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: manager.isBusy ? null : _submitEmailAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _silverAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      _silverAccent.withValues(alpha: 0.56),
                  disabledForegroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: manager.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _isRegisterMode
                            ? 'إنشاء الحساب والمتابعة'
                            : 'تسجيل الدخول',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                        ),
                      ),
              ),
            ),
            if (widget.redirectToHomeOnSuccess) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: manager.isBusy ? null : _continueWithoutLogin,
                style: TextButton.styleFrom(
                  foregroundColor: _silverAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: const Text(
                  'المتابعة بدون تسجيل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: _silverAccent.withValues(alpha: 0.22),
      ),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: _authInput,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: _silverAccent.withValues(alpha: 0.95),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(
          color: _silverAccent.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.4,
        ),
      ),
      errorStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.error,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _authInput,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _silverAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeItem(
              title: 'تسجيل الدخول',
              selected: !_isRegisterMode,
              onTap: () {
                setState(() => _isRegisterMode = false);
              },
            ),
          ),
          Expanded(
            child: _buildModeItem(
              title: 'إنشاء حساب',
              selected: _isRegisterMode,
              onTap: () {
                setState(() => _isRegisterMode = true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? Colors.white : Colors.transparent,
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? Colors.black : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons({
    required bool busy,
    required bool canUseApple,
  }) {
    return Column(
      children: [
        _socialButton(
          label: 'المتابعة عبر Google',
          icon: Icons.g_mobiledata_rounded,
          brandColor: const Color(0xFF8AB4F8),
          onTap: busy ? null : _loginWithGoogle,
        ),
        if (canUseApple) ...[
          const SizedBox(height: 8),
          _socialButton(
            label: 'المتابعة عبر Apple',
            icon: Icons.apple,
            brandColor: const Color(0xFFE8ECF4),
            onTap: busy ? null : _loginWithApple,
          ),
        ],
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required Color brandColor,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary.withValues(alpha: 0.96),
          backgroundColor: _authInput.withValues(alpha: 0.75),
          side: BorderSide(
            color: _silverAccent.withValues(alpha: 0.30),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: brandColor,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_authTop, _authBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowCircle(
              size: 290,
              color: _silverAccent.withValues(alpha: 0.11),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -70,
            child: _GlowCircle(
              size: 260,
              color: _silverAccent.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            top: 210,
            left: -40,
            child: _GlowCircle(
              size: 170,
              color: _silverAccent.withValues(alpha: 0.07),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 12,
          ),
        ],
      ),
    );
  }
}
