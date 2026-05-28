import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'routes/app_routes.dart';
import 'utils/constants.dart';
import 'langs/messages.dart';
import 'controllers/auth_controller.dart';
import 'utils/storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalStorage.getInstance();
  await initializeDateFormatting();
  Get.put(AuthController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Locale _getSavedLocale() {
    final languageIndex = GlobalStorage.getLanguage();
    return languageIndex == 0
        ? const Locale('en', 'US')
        : const Locale('zh', 'CN');
  }

  String _getInitialRoute() {
    final token = GlobalStorage.getToken();
    if (token != null && token.isNotEmpty) {
      return AppRoutes.home;
    }
    return AppRoutes.login;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SunBox Cloud',
      // builder: (context, child) {
      //   return MediaQuery(
      //     data: MediaQuery.of(context).copyWith(
      //       textScaler: TextScaler.noScaling, // 禁止系统缩放
      //     ),
      //     child: child!,
      //   );
      // },
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor),
          ),
        ),
      ),
      translations: Messages(),
      locale: _getSavedLocale(),
      fallbackLocale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
      initialRoute: _getInitialRoute(),
      getPages: AppRoutes.routes,
    );
  }
}
