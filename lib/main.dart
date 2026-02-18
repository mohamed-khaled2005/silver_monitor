import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'screens/splash_screen.dart';
import 'providers/gold_provider.dart';
import 'utils/constants.dart';

// ✅ ADD
import 'utils/app_lifecycle_refresh.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ OneSignal init
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("cbc64a78-e9bf-413b-a050-df71c27bd1bf");

  // ✅ طلب إذن الإشعارات (iOS + Android 13+)
  await OneSignal.Notifications.requestPermission(true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _refreshSilver(BuildContext context) async {
    final provider = context.read<GoldProvider>();

    if (provider.isLoading) return;

    final empty = provider.currentGoldPrice == null &&
        provider.calibers.isEmpty &&
        provider.bullions.isEmpty;

    try {
      if (empty) {
        await provider.initializeData();
      } else {
        // يجدد نفس العملة (وبيعمل fetch داخلياً)
        provider.setCurrency(provider.selectedCurrency);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoldProvider(),
      child: AppLifecycleRefresh(
        // ✅ العميل عايز كل مرة يرجع (حتى لو سريع)
        minInterval: Duration.zero,
        minBackgroundDuration: Duration.zero,

        // ✅ لما يفتح التطبيق (cold start) كمان
        refreshOnStart: true,

        onResumed: _refreshSilver,
        child: MaterialApp(
          title: 'مراقب الفضة',
          debugShowCheckedModeBanner: false,

          // ✅ RTL
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },

          theme: ThemeData(
            primaryColor: AppColors.primaryGold,
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: 'Tajawal',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Tajawal',
              ),
              iconTheme: IconThemeData(color: AppColors.primaryGold),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: AppColors.cardDark,
              selectedItemColor: AppColors.primaryGold,
              unselectedItemColor: AppColors.textSecondary,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),

          home: const SplashScreen(),
        ),
      ),
    );
  }
}
