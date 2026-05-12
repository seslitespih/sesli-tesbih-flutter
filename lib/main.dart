import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/locale_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/dua_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/privacy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await LocaleService.instance.load();
  runApp(const SesliTesbihApp());
}

class SesliTesbihApp extends StatelessWidget {
  const SesliTesbihApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Sesli Tesbih',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/main': (_) => const MainScreen(),
            '/dua': (_) => const DuaScreen(),
            '/prayer': (_) => const PrayerTimesScreen(),
            '/qibla': (_) => const QiblaScreen(),
            '/privacy': (_) => const PrivacyScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/counter') {
              final dhikrId = settings.arguments as int? ?? 1;
              return MaterialPageRoute(
                builder: (_) => CounterScreen(dhikrId: dhikrId),
              );
            }
            return null;
          },
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        primary: const Color(0xFF2E7D32),
        secondary: const Color(0xFF66BB6A),
        surface: Colors.white,
        background: const Color(0xFFF1F8E9),
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F8E9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}

// App-wide color constants
class AppColors {
  static const Color greenDark = Color(0xFF1B5E20);
  static const Color greenMid = Color(0xFF2E7D32);
  static const Color greenAccent = Color(0xFF4CAF50);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color background = Color(0xFFF1F8E9);
}
