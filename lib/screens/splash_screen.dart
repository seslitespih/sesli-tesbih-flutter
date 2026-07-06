import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _starAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.1, 0.7, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.75, curve: Curves.elasticOut),
      ),
    );
    _starAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF10234C),
              Color(0xFF16305F),
              Color(0xFF1E3A6E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Altın hilal
                      SizedBox(
                        width: 104,
                        height: 104,
                        child: CustomPaint(
                          painter: _CrescentPainter(
                            progress: _starAnim.value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Arabic subtitle
                      const Text(
                        'سبحان الله',
                        style: TextStyle(
                          color: Color(0xFFC9A227),
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      // App name
                      const Text(
                        'Vocal Tasbeeh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Vocal Islamic Dhikr Counter',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 13,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Loading dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final delay = i / 3;
                          final v = ((_ctrl.value - delay).clamp(0.0, 0.33) / 0.33);
                          return Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: v * 0.8),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Zarif altın hilal: iki dairenin farkından oluşur, hafif ışıltılı.
class _CrescentPainter extends CustomPainter {
  final double progress;
  const _CrescentPainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    final crescent = Path()
      ..addOval(Rect.fromCircle(center: center, radius: r))
      ..addOval(Rect.fromCircle(
        center: center.translate(r * 0.42, -r * 0.10),
        radius: r * 0.82,
      ))
      ..fillType = PathFillType.evenOdd;

    // Glow
    canvas.drawPath(
      crescent,
      Paint()
        ..color = const Color(0xFFC9A227).withValues(alpha: 0.35 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Altın degrade dolgu
    canvas.drawPath(
      crescent,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0x00E5C96B), const Color(0xFFE5C96B),
                progress)!,
            Color.lerp(const Color(0x00A8861D), const Color(0xFFA8861D),
                progress)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Hilalin ucunda minik yıldız noktası
    final dot = center.translate(r * 0.78 * math.cos(-math.pi / 3.2),
        r * 0.78 * math.sin(-math.pi / 3.2));
    canvas.drawCircle(
      dot,
      3.2 * progress,
      Paint()..color = Colors.white.withValues(alpha: 0.9 * progress),
    );
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => progress != old.progress;
}
