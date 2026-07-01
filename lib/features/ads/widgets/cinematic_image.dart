import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';

// ── Cinematic Image Engine ────────────────────────────────────────────────────

/// Static helpers used by [CinematicImage].
/// URL upgrade is also safe to call from outside this file.
class CinematicImageEngine {
  const CinematicImageEngine._();

  /// Rewrites an Unsplash URL to 1920 × 1080 at 95 % quality.
  /// All other URLs pass through unchanged.
  static String upgradeUrl(String url) {
    if (!url.startsWith('http') || !url.contains('images.unsplash.com')) {
      return url;
    }
    try {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters)
        ..['w'] = '1920'
        ..['h'] = '1080'
        ..['q'] = '95'
        ..['fit'] = 'crop'
        ..['auto'] = 'format';
      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }

  // 4 × 5 row-major RGBA colour matrix — teal-orange cinematic grade.
  //   • Shadows pushed toward teal   (blue-green channel lifted in darks)
  //   • Highlights pushed warm orange (red channel boosted)
  //   • Overall contrast raised
  static const List<double> gradeMatrix = [
    //   R      G      B     A   offset
     1.18,  0.00, -0.05, 0.0, -0.03,   // → R out
     0.00,  0.92,  0.00, 0.0,  0.04,   // → G out
    -0.18, -0.05,  1.20, 0.0,  0.10,   // → B out
     0.00,  0.00,  0.00, 1.0,  0.00,   // → A out
  ];
}

// ── CinematicImage ────────────────────────────────────────────────────────────

/// Drop-in replacement for [PropertyImageWidget] inside ad contexts.
///
/// Layers applied bottom-to-top:
///   1. Base image at 1080 p quality with teal-orange colour grade
///   2. Radial vignette  (darkens edges)
///   3. Static film grain (analogue texture)
///   4. 2.39 : 1 letterbox bars  (optional, default off)
class CinematicImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// 2.39 : 1 widescreen black bars.  Off by default for full-screen use;
  /// enable for contained card previews where the bars complete the look.
  final bool letterbox;

  /// Static film-grain overlay.
  final bool grain;

  /// Radial vignette that darkens the edges.  Disable when the parent widget
  /// already supplies its own top-to-bottom gradient.
  final bool vignette;

  const CinematicImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.letterbox = false,
    this.grain = true,
    this.vignette = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Colour-graded base image (1080 p quality)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(CinematicImageEngine.gradeMatrix),
            child: PropertyImageWidget(
              path: CinematicImageEngine.upgradeUrl(path),
              width: width,
              height: height,
              fit: fit,
            ),
          ),

          // 2. Radial vignette
          if (vignette)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.05,
                  colors: [
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0x44000000),
                    Color(0xAA000000),
                  ],
                  stops: [0.0, 0.45, 0.72, 1.0],
                ),
              ),
            ),

          // 3. Film grain — fixed seed keeps the pattern stable (no flicker)
          if (grain)
            const CustomPaint(painter: _GrainPainter()),

          // 4. Letterbox bars — 2.39 : 1 (≈ 13 % per bar)
          if (letterbox)
            const _LetterboxBars(),
        ],
      ),
    );
  }
}

// ── Film Grain ────────────────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // fixed seed → stable pattern, zero flicker

    // Halved ceiling vs original to cut raster work on software renderers.
    // Density formula keeps fewer dots on small cards, more on full-screen ads.
    final count = (size.width * size.height / 560).round().clamp(400, 3500);

    // Draw all grain into a single composited layer so the overlay blend is
    // one GPU operation instead of <count> individual read-modify-write cycles.
    // This is the key fix for EGL/software-rendered surfaces (Android emulator).
    final layerPaint = Paint()..blendMode = BlendMode.overlay;
    canvas.saveLayer(Offset.zero & size, layerPaint);

    final dotPaint = Paint(); // srcOver inside the layer — cheap
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      // Slightly higher per-dot opacity to compensate for fewer dots.
      dotPaint.color = rng.nextBool()
          ? Color.fromRGBO(255, 255, 255, rng.nextDouble() * 0.18)
          : Color.fromRGBO(0, 0, 0, rng.nextDouble() * 0.14);
      canvas.drawCircle(Offset(x, y), 0.85, dotPaint);
    }

    canvas.restore(); // apply the overlay blend in one pass
  }

  @override
  bool shouldRepaint(_GrainPainter _) => false;
}

// ── Letterbox Bars ────────────────────────────────────────────────────────────

class _LetterboxBars extends StatelessWidget {
  const _LetterboxBars();

  @override
  Widget build(BuildContext context) {
    // flex totals 100: 13 top-bar + 74 active-area + 13 bottom-bar
    return const Column(
      children: [
        Expanded(flex: 13, child: ColoredBox(color: Colors.black, child: SizedBox.expand())),
        Spacer(flex: 74),
        Expanded(flex: 13, child: ColoredBox(color: Colors.black, child: SizedBox.expand())),
      ],
    );
  }
}
