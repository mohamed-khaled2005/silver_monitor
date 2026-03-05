import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/app_manager_provider.dart';
import 'providers/gold_provider.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';
import 'utils/app_lifecycle_refresh.dart';
import 'utils/constants.dart';
import 'widgets/app_manager_lifecycle_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  PushNotificationService.registerBackgroundHandler();

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
        provider.setCurrency(provider.selectedCurrency);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GoldProvider>(
          create: (_) => GoldProvider(),
        ),
        ChangeNotifierProvider<AppManagerProvider>(
          create: (_) => AppManagerProvider()..initialize(),
        ),
      ],
      child: AppManagerLifecycleObserver(
        child: AppLifecycleRefresh(
          minInterval: Duration.zero,
          minBackgroundDuration: Duration.zero,
          refreshOnStart: true,
          onResumed: _refreshSilver,
          child: MaterialApp(
            title: 'مراقب الفضة',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => child ?? const SizedBox.shrink(),
            theme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryGold,
                brightness: Brightness.dark,
              ).copyWith(
                primary: AppColors.primaryGold,
                surface: AppColors.cardDark,
                onSurface: AppColors.textPrimary,
              ),
              primaryColor: AppColors.primaryGold,
              scaffoldBackgroundColor: AppColors.background,
              fontFamily: 'Tajawal',
              textTheme: ThemeData.dark().textTheme.apply(
                    bodyColor: AppColors.textPrimary,
                    displayColor: AppColors.textPrimary,
                    fontFamily: 'Tajawal',
                  ),
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                ),
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                  fontFamily: 'Tajawal',
                ),
                floatingLabelStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800,
                ),
                prefixIconColor: AppColors.textSecondary,
                suffixIconColor: AppColors.textSecondary,
              ),
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppColors.textPrimary,
                selectionColor: AppColors.textPrimary.withValues(alpha: 0.26),
                selectionHandleColor: AppColors.primaryGold,
              ),
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
      ),
    );
  }
}

