import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _bgColor = Color(0xFF0A0A0A);
  static const _crimson = Color(0xFF8B1020);

  late final AnimationController _glowCtrl;
  late final AnimationController _spinCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _navigate();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _awaitAuth() async {
    for (var i = 0; i < 60 && ref.read(authProvider).isLoading; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> _navigate() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2600)),
      _awaitAuth(),
    ]);
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('taftaf_onboarding_done') ?? false;
    if (!mounted) return;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go(authState.currentUser!.isOwner
          ? AppRoutes.ownerHome
          : AppRoutes.clientHome);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Pulsing crimson radial glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, _) => CustomPaint(
                painter: _GlowPainter(intensity: _glowAnim.value),
              ),
            ),
          ),

          // Main content column — explicitly centered
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              // ── TAFTAF ────────────────────────────────────────────────────
              const Text(
                'TAFTAF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 16,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Color(0x668B1020),
                      blurRadius: 48,
                      offset: Offset.zero,
                    ),
                    Shadow(
                      color: Color(0x338B1020),
                      blurRadius: 90,
                      offset: Offset.zero,
                    ),
                  ],
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    duration: 950.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms)
                  .then(delay: 150.ms)
                  .shimmer(
                    duration: 1100.ms,
                    color: Colors.white.withValues(alpha: 0.55),
                    angle: 30,
                  ),

              const SizedBox(height: 8),

              // ── Expanding gradient separator ───────────────────────────────
              const SizedBox(height: 1)
                  .animate()
                  .custom(
                    duration: 550.ms,
                    delay: 550.ms,
                    curve: Curves.easeOut,
                    builder: (_, value, __) => Container(
                      width: 190 * value,
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _crimson,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 12),

              // ── Commercial Agency ──────────────────────────────────────────
              const Text(
                'C O M M E R C I A L   A G E N C Y',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                ),
              )
                  .animate()
                  .fadeIn(delay: 650.ms, duration: 700.ms)
                  .slideY(
                    begin: 0.7,
                    end: 0,
                    delay: 650.ms,
                    duration: 700.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 80),

              // ── Arc spinner ────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, _) => CustomPaint(
                  size: const Size(38, 38),
                  painter: _ArcSpinner(
                    progress: _spinCtrl.value,
                    color: _crimson,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 500.ms)
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1.0, 1.0),
                    delay: 1000.ms,
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

// ── Pulsing crimson radial glow ──────────────────────────────────────────────

class _GlowPainter extends CustomPainter {
  final double intensity;
  static const _crimson = Color(0xFF8B1020);

  const _GlowPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final radius = size.width * 0.78;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [
            _crimson.withValues(alpha: 0.22 * intensity),
            _crimson.withValues(alpha: 0.07 * intensity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.intensity != intensity;
}

// ── Rotating arc loader ──────────────────────────────────────────────────────

class _ArcSpinner extends CustomPainter {
  final double progress;
  final Color color;

  const _ArcSpinner({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;

    // Faint track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Glowing sweeping arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2 * math.pi * progress - math.pi / 2,
      math.pi * 1.25,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Bright leading dot
    final leadAngle = 2 * math.pi * progress - math.pi / 2 + math.pi * 1.25;
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(leadAngle),
        center.dy + radius * math.sin(leadAngle),
      ),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_ArcSpinner old) => old.progress != progress;
}
