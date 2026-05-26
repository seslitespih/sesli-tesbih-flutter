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
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
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
                      // Islamic 8-pointed star
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CustomPaint(
                          painter: _IslamicStarPainter(
                            progress: _starAnim.value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Arabic subtitle
                      const Text(
                        'سبحان الله',
                        style: TextStyle(
                          color: Color(0xFFFFCA28),
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

class _IslamicStarPainter extends CustomPainter {
  final double progress;
  const _IslamicStarPainter({this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.42;
    const points = 8;

    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFCA28).withValues(alpha: 0.3 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFFFCA28).withValues(alpha: 0.0),
          const Color(0xFFFFCA28),
          progress,
        )!
        ..style = PaintingStyle.fill,
    );

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_IslamicStarPainter old) => progress != old.progress;
}
