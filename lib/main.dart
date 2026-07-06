import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/locale_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/dua_screen.dart';
import 'screens/esma_screen.dart';
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
          title: 'Vocal Tasbeeh',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/main': (_) => const MainScreen(),
            '/dua': (_) => const DuaScreen(),
            '/esma': (_) => const EsmaScreen(),
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
        seedColor: const Color(0xFF16305F),
        primary: const Color(0xFF16305F),
        secondary: const Color(0xFFC9A227),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F5EF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16305F),
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
          backgroundColor: const Color(0xFF16305F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}

// App-wide color constants — lacivert (navy) + koyu altın (dark gold) tema.
// Not: isimler tarihsel ("green*"); değerler lacivert/altın paletidir.
class AppColors {
  static const Color greenDark = Color(0xFF0E1F45);   // koyu lacivert
  static const Color greenMid = Color(0xFF16305F);    // lacivert
  static const Color greenAccent = Color(0xFFC9A227); // koyu altın
  static const Color greenLight = Color(0xFFEDE7D4);  // fildişi-altın zemin
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1B2437);
  static const Color textSecondary = Color(0xFF6E7486);
  static const Color background = Color(0xFFF7F5EF);  // sıcak fildişi

  static const Color gold = Color(0xFFC9A227);
  static const Color goldDeep = Color(0xFFA8861D);
  static const Color goldLight = Color(0xFFE5C96B);
  static const List<Color> navyGradient = [
    Color(0xFF0A1735), Color(0xFF14294F), Color(0xFF1E3A6E),
  ];
}
