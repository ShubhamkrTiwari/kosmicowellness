import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'managers/cart_manager.dart';
import 'managers/user_manager.dart';
import 'managers/theme_manager.dart';
import 'managers/notification_manager.dart';
import 'managers/payment_manager.dart';
import 'managers/care_manager.dart';
import 'managers/language_manager.dart';
import 'utils/keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserManager().init();
  await ThemeManager().init();
  await LanguageManager().init();
  await NotificationManager().init();
  await PaymentManager().init();
  await CareManager().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LanguageManager()]),
      builder: (context, _) {
        final bool isDark = ThemeManager().isDarkMode == true;
        final lang = LanguageManager();
        
        return MaterialApp(
          key: ValueKey(LanguageManager().currentLanguage), // Force full rebuild on language change
          title: lang.translate('app_title'),
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00833E),
              primary: const Color(0xFF00833E),
              secondary: const Color(0xFF1B264F),
              surface: const Color(0xFFEBF7F2), 
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.black,
              onSurfaceVariant: Colors.black,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: Color(0xFF00833E)),
              titleLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.w600),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00833E),
              brightness: Brightness.dark,
              primary: const Color(0xFF00833E),
              secondary: const Color(0xFF4CBB17),
              surface: const Color(0xFF121212),
              surfaceContainerHighest: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
              onSurfaceVariant: Colors.grey[400],
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              elevation: 0,
              centerTitle: true,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.bold, color: Colors.white),
              titleLarge: TextStyle(fontFamily: 'Serif', fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
