import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../animations/fade_animation.dart';
import '../widgets/app_section_header.dart';

/// 🎨 لون فضي محلي لشاشة الاتصال والصفحات القانونية
const Color _silverAccent = Color(0xFFC0C5D5);

class ContactScreen extends StatelessWidget {
  const ContactScreen({Key? key}) : super(key: key);

  static const String _websiteUrl = 'https://almurakib.com';
  static const String _email = 'info@almurakib.com';
  static const String _phone = '+3197010284689';
  static const String _whatsAppNumber = '3197010284689';
  static const String _telegramUrl = 'https://t.me/Almurakib';

  // نص سياسة الخصوصية
  static const String _privacyPolicyText = '''
نحن في تطبيق “مراقب الفضة” نحترم خصوصيتك ونسعى لحماية بياناتك الشخصية وفق أفضل الممارسات.

المعلومات التي نقوم بجمعها
قد يقوم التطبيق بجمع أنواع محدودة من البيانات بهدف تحسين الخدمة، وتشمل:
• معلومات الاستخدام العامة (مثل الصفحات التي تزورها داخل التطبيق).
• بيانات الجهاز (نوع الجهاز، إصدار النظام).
• معلومات التحليلات المجهولة لتحسين الأداء.

لا يجمع التطبيق أي معلومات مالية أو شخصية حساسة مثل الاسم أو البريد الإلكتروني أو الموقع الجغرافي الدقيق، إلا إذا قام المستخدم بتقديمها طوعًا.

كيفية استخدام المعلومات
نستخدم البيانات فقط من أجل:
• تحسين تجربة المستخدم.
• تطوير ميزات التطبيق.
• تحليل الأداء وحل المشاكل التقنية.

لا نقوم ببيع أو مشاركة بيانات المستخدم مع أي طرف ثالث إلا عند الضرورة التشغيلية أو وفقًا للقانون.

ملفات تعريف الارتباط (Cookies)
قد يستخدم التطبيق تقنيات مشابهة للكوكيز لتحسين الأداء، دون جمع أي بيانات تعريف شخصية.

حماية البيانات
نعتمد مجموعة من الإجراءات التقنية للمحافظة على أمان المعلومات ومنع الوصول غير المصرح به.

التعديلات على سياسة الخصوصية
قد نقوم بتحديث هذه السياسة من وقت لآخر، وسيتم نشر النسخة المحدّثة داخل التطبيق.

باستخدامك للتطبيق فإنك توافق على سياسة الخصوصية هذه.
''';

  // نص إخلاء المسؤولية
  static const String _disclaimerText = '''
تطبيق “مراقب الفضة” يقدّم بيانات وأسعار الفضة لأغراض معلوماتية فقط، ولا يضمن دقّتها بنسبة 100% في جميع الأوقات. يتم جمع الأسعار من مزوّدي بيانات خارجيين، وقد تتغير القيم دون إشعار مسبق نتيجة تقلبات الأسواق أو تأخر التحديث أو اعتماد مصادر متعددة.

لا يتحمل التطبيق أو موقع المراقب أي مسؤولية عن:
• أي خسائر مالية أو قرارات استثمارية يتم اتخاذها اعتمادًا على المعلومات المعروضة.
• تأخر أو انقطاع في عرض الأسعار.
• اختلاف الأسعار بين التطبيق والأسواق الفعلية.
• أي أضرار مباشرة أو غير مباشرة ناتجة عن استخدام التطبيق.

يُنصح المستخدم دائمًا بالتحقق من الأسعار من مصادر مالية رسمية قبل اتخاذ أي قرار شراء أو بيع.

باستخدامك للتطبيق فإنك تقرّ بأن استخدامك يتم على مسؤوليتك الشخصية.
''';

  // نص الشروط والأحكام
  static const String _termsText = '''
يرجى قراءة هذه الشروط بعناية قبل استخدام تطبيق “مراقب الفضة”. استخدامك للتطبيق يعني موافقتك الكاملة على جميع الشروط أدناه:

1. قبول الشروط
باستخدام التطبيق، أنت توافق على الالتزام بهذه الشروط وجميع السياسات المرتبطة به مثل سياسة الخصوصية وإخلاء المسؤولية.

2. استخدام التطبيق
• يهدف التطبيق لتوفير معلومات سعرية فقط، ولا يُعدّ أداة تداول أو استشارة مالية.
• يُحظر استخدام التطبيق لأي نشاط غير قانوني أو يضر بالخدمة أو بالمستخدمين الآخرين.
• قد نقوم بإيقاف أو تعديل الخدمة دون إشعار مسبق.

3. الملكية الفكرية
جميع المحتويات والبيانات والتصاميم داخل التطبيق ملك لموقع المراقب ولا يجوز إعادة استخدامها أو نسخها دون إذن خطي.

4. دقة البيانات
رغم سعينا لتوفير بيانات دقيقة ومحدثة، قد تظهر فروقات أو تأخر في الأسعار. لا نتحمل مسؤولية أي قرارات مالية تعتمد على البيانات داخل التطبيق.

5. تحديثات التطبيق
قد نقوم بتحديث التطبيق وتحسينه بشكل دوري. قد تتغير بعض الميزات أو تختفي دون إشعار مسبق.

6. حدود المسؤولية
لا يتحمل التطبيق أو موقع المراقب أي خسائر ناتجة عن:
• الاعتماد على أسعار أو بيانات غير محدثة.
• توقف الخدمة أو حدوث أعطال تقنية.
• سوء استخدام التطبيق من قبل المستخدم.

7. إنهاء الاستخدام
يحق لنا إنهاء أو تعليق وصول المستخدم للتطبيق في حال مخالفة الشروط أو إساءة استخدام الخدمة.

8. القانون المُطبق
تخضع هذه الشروط لقوانين الجهة المالكة للموقع، وأي نزاعات تُحل وفق الإجراءات القانونية المعمول بها.

باستخدامك للتطبيق، فإنك تؤكد موافقتك على هذه الشروط والأحكام.
''';

  @override
  Widget build(BuildContext context) {
    return FadeAnimation(
      child: SingleChildScrollView(
        padding: Responsive.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const AppSectionHeader(title: 'الاتصال بنا'),
            const SizedBox(height: 16),
            _buildCompanyCard(),
            const SizedBox(height: 24),
            _buildContactInfo(context),
            const SizedBox(height: 24),
            _buildWhatsAppButton(context),
            const SizedBox(height: 12),
            _buildTelegramButton(context),
            const SizedBox(height: 24),
            _buildLegalButtons(context),
          ],
        ),
      ),
    );
  }

  /// بطاقة "شركة وموقع المراقب"
  Widget _buildCompanyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'شركة وموقع المراقب',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'شركة رسمية مرخصة في دولة بيليز تحت اسم ( Almurakib LLC )',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// معلومات الاتصال (موقع / بريد / هاتف)
  Widget _buildContactInfo(BuildContext context) {
    final List<_ContactItem> items = [
      _ContactItem(
        icon: Icons.language,
        title: 'الموقع الإلكتروني',
        value: _websiteUrl,
        onTap: () => _launchUrl(Uri.parse(_websiteUrl)),
      ),
      _ContactItem(
        icon: Icons.email_outlined,
        title: 'البريد الإلكتروني',
        value: _email,
        onTap: () => _launchUrl(Uri(
          scheme: 'mailto',
          path: _email,
        )),
      ),
      _ContactItem(
        icon: Icons.phone_android,
        title: 'رقم الهاتف',
        value: _phone,
        onTap: () => _launchUrl(Uri(
          scheme: 'tel',
          path: _phone,
        )),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات الاتصال',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: items
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: _silverAccent.withAlpha(
                        (0.20 * 255).toInt(),
                      ),
                      child: Icon(
                        item.icon,
                        color: _silverAccent,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: item.title == 'رقم الهاتف'
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              item.value,
                              style: AppTextStyles.bodySmall,
                              textDirection: TextDirection.ltr,
                            ),
                          )
                        : Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              item.value,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                    onTap: item.onTap,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  /// زر واتساب
  Widget _buildWhatsAppButton(BuildContext context) {
    final Uri waUri = Uri.parse('https://wa.me/$_whatsAppNumber');

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _launchUrl(waUri),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
        label: const Text(
          'التواصل عبر واتساب',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// زر تليجرام
  Widget _buildTelegramButton(BuildContext context) {
    final Uri telegramUri = Uri.parse(_telegramUrl);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _launchUrl(telegramUri),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF229ED9),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(
          Icons.telegram,
          color: Colors.white,
        ),
        label: const Text(
          'التواصل عبر تلجرام',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// أزرار سياسة الخصوصية / إخلاء المسؤولية / الشروط
  Widget _buildLegalButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الصفحات القانونية',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _legalButton(
              context: context,
              title: 'إخلاء المسؤولية',
              onTap: () => _showPolicySheet(
                context: context,
                title: 'إخلاء المسؤولية',
                content: _disclaimerText,
              ),
            ),
            _legalButton(
              context: context,
              title: 'سياسة الخصوصية',
              onTap: () => _showPolicySheet(
                context: context,
                title: 'سياسة الخصوصية',
                content: _privacyPolicyText,
              ),
            ),
            _legalButton(
              context: context,
              title: 'الشروط والأحكام',
              onTap: () => _showPolicySheet(
                context: context,
                title: 'الشروط والأحكام',
                content: _termsText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legalButton({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _silverAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: _silverAccent,
          fontFamily: 'Tajawal',
          fontSize: 13,
        ),
      ),
    );
  }

  void _showPolicySheet({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Text(
                        content,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _launchUrl(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ContactItem {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
}
