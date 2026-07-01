import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/ad_model.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';

class PropertyAdOverlay extends StatefulWidget {
  final AdWithProperty adWithProperty;
  final VoidCallback onDismiss;

  const PropertyAdOverlay({
    super.key,
    required this.adWithProperty,
    required this.onDismiss,
  });

  @override
  State<PropertyAdOverlay> createState() => _PropertyAdOverlayState();
}

class _PropertyAdOverlayState extends State<PropertyAdOverlay>
    with SingleTickerProviderStateMixin {
  static const _totalSecs = 10;

  late final AnimationController _ringCtrl;
  Timer? _imageTimer;
  Timer? _secsTimer;

  int _imgIndex = 0;
  int _secsLeft = _totalSecs;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalSecs),
    )..forward();

    _ringCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _canSkip = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onDismiss();
        });
      }
    });

    _secsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secsLeft = (_secsLeft - 1).clamp(0, _totalSecs));
    });

    final images = widget.adWithProperty.property.images;
    if (images.length > 1) {
      _imageTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
        if (!mounted) return;
        setState(() => _imgIndex = (_imgIndex + 1) % images.length);
      });
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _imageTimer?.cancel();
    _secsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.adWithProperty.property;
    final images = property.images;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Material(
        color: Colors.black,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background images: smooth crossfade with gentle scale ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 900),
                transitionBuilder: (child, animation) {
                  final scale = Tween<double>(begin: 1.06, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
                child: images.isNotEmpty
                    ? PropertyImageWidget(
                        key: ValueKey(_imgIndex),
                        path: images[_imgIndex % images.length],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        key: const ValueKey(-1),
                        color: AppColors.surface,
                      ),
              ),

              // ── Gradient overlay for text readability ──────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22000000),
                        Color(0x10000000),
                        Color(0x99000000),
                        Color(0xEE000000),
                      ],
                      stops: [0.0, 0.30, 0.58, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Top bar: SPONSORED badge + image dot indicators ────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded,
                                size: 13, color: AppColors.black),
                            SizedBox(width: 4),
                            Text(
                              'SPONSORED',
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(
                            duration: 2200.ms,
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                      const Spacer(),
                      if (images.length > 1)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            images.length.clamp(0, 5),
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: i == _imgIndex ? 20 : 6,
                              height: 6,
                              margin: const EdgeInsets.only(left: 5),
                              decoration: BoxDecoration(
                                color: i == _imgIndex
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 250.ms),
                ),
              ),

              // ── Bottom content panel ───────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    22, 0, 22,
                    MediaQuery.of(context).padding.bottom + 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Property type pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        child: Text(
                          property.typeLabel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Title
                      Text(
                        property.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          shadows: [
                            Shadow(blurRadius: 12, color: Colors.black54)
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              property.location,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Price + controls row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.priceFormatted,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              if (property.priceSuffix.isNotEmpty)
                                Text(
                                  property.priceSuffix,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.55),
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),

                          // Skip / countdown + View CTA
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _canSkip
                                    ? GestureDetector(
                                        key: const ValueKey('skip'),
                                        onTap: widget.onDismiss,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.25)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Skip',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              SizedBox(width: 4),
                                              Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Colors.white,
                                                  size: 16),
                                            ],
                                          ),
                                        ),
                                      )
                                        .animate()
                                        .fadeIn(duration: 280.ms)
                                        .slideX(begin: 0.4)
                                    : _CountdownRing(
                                        key: const ValueKey('ring'),
                                        controller: _ringCtrl,
                                        secsLeft: _secsLeft,
                                      ),
                              ),
                              const SizedBox(height: 12),

                              // View Property CTA
                              GestureDetector(
                                onTap: () {
                                  widget.onDismiss();
                                  context.push(AppRoutes.propertyDetailPath(
                                      property.id));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.42),
                                        blurRadius: 22,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.open_in_new_rounded,
                                          size: 15, color: AppColors.black),
                                      SizedBox(width: 8),
                                      Text(
                                        'View Property',
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ).animate().slideY(begin: 0.08, delay: 180.ms).fadeIn(delay: 180.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 420.ms);
  }
}

// ── Countdown ring ────────────────────────────────────────────────────────────

class _CountdownRing extends StatelessWidget {
  final AnimationController controller;
  final int secsLeft;

  const _CountdownRing({super.key, required this.controller, required this.secsLeft});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: controller.value,
              strokeWidth: 2.5,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            Text(
              '$secsLeft',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
