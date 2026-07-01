import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ── Property List Card (vertical, auto-sliding images) ───────────────────────

class PropertyListCard extends ConsumerStatefulWidget {
  final PropertyModel property;
  final bool showActions;
  final String? distanceLabel;

  const PropertyListCard({
    super.key,
    required this.property,
    this.showActions = false,
    this.distanceLabel,
  });

  @override
  ConsumerState<PropertyListCard> createState() => _PropertyListCardState();
}

class _PropertyListCardState extends ConsumerState<PropertyListCard> {
  late final PageController _pageCtrl;
  int _currentImage = 0;
  Timer? _timer;

  PropertyModel get property => widget.property;

  String get _statusLabel {
    if (!property.isAvailable) return 'Unavailable';
    if (property.priceType == PriceType.fixed || property.type == PropertyType.plot) return 'For Sale';
    return 'Available';
  }

  Color get _statusBg {
    if (!property.isAvailable) return AppColors.surface;
    if (property.priceType == PriceType.fixed || property.type == PropertyType.plot) return const Color(0xFF0D3320);
    return AppColors.primarySurface;
  }

  Color get _statusTextColor {
    if (!property.isAvailable) return AppColors.textMuted;
    if (property.priceType == PriceType.fixed || property.type == PropertyType.plot) return AppColors.success;
    return AppColors.primary;
  }

  IconData _typeIcon(PropertyType type) {
    switch (type) {
      case PropertyType.airbnb:     return Icons.nightlife_rounded;
      case PropertyType.apartment:  return Icons.apartment_rounded;
      case PropertyType.house:      return Icons.house_rounded;
      case PropertyType.plot:       return Icons.terrain_rounded;
      case PropertyType.commercial: return Icons.store_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    // Timer is started only when this card claims the active-slide slot
    // (see VisibilityDetector + ref.listen below).
  }

  void _startAutoSlide() {
    if (property.images.length <= 1) return;
    if (_timer != null && _timer!.isActive) return; // already running
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentImage + 1) % property.images.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoSlide() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final isLiked = user != null && property.likedBy.contains(user.id);
    final isVerified = property.isVerified;
    final images = property.images;

    // React to the global active-card slot: start/stop this card's timer
    // whenever ownership of the slot changes.
    ref.listen<String?>(activeSlidingCardProvider, (prev, next) {
      final wasActive = prev == property.id;
      final isNowActive = next == property.id;
      if (!wasActive && isNowActive) _startAutoSlide();
      if (wasActive && !isNowActive) _stopAutoSlide();
    });

    return VisibilityDetector(
      key: Key('prop-card-${property.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= 0.75) {
          // Claim the slot only when no other card holds it (or we already do).
          final current = ref.read(activeSlidingCardProvider);
          if (current == null || current == property.id) {
            ref.read(activeSlidingCardProvider.notifier).state = property.id;
          }
        } else if (info.visibleFraction < 0.35) {
          // Release the slot when this card scrolls mostly off-screen.
          if (ref.read(activeSlidingCardProvider) == property.id) {
            ref.read(activeSlidingCardProvider.notifier).state = null;
          }
        }
      },
      child: GestureDetector(
      onTap: () => context.push(AppRoutes.propertyDetailPath(property.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.divColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image carousel ────────────────────────────────────────────
            Stack(
              children: [
                // Slideshow
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: images.isEmpty
                        ? PropertyImageWidget(path: '', width: double.infinity, height: 200)
                        : PageView.builder(
                            controller: _pageCtrl,
                            onPageChanged: (i) => setState(() => _currentImage = i),
                            itemCount: images.length,
                            itemBuilder: (_, i) => PropertyImageWidget(
                              path: images[i],
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                  ),
                ),

                // Bottom gradient scrim
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                      ),
                    ),
                  ),
                ),

                // Status badge — top left
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(color: _statusTextColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                // Property type pill — top right (replaces heart button)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon(property.type), size: 12, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          property.typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom row: like button | dot indicators | verified badge
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Row(
                      children: [
                        // Like button — bottom left
                        GestureDetector(
                          onTap: () {
                            if (user != null) {
                              ref.read(propertyProvider.notifier).toggleLike(property.id, user.id);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isLiked
                                  ? AppColors.primary.withValues(alpha: 0.18)
                                  : Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLiked
                                    ? AppColors.primary.withValues(alpha: 0.55)
                                    : Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? AppColors.primary : Colors.white,
                              size: 15,
                            ),
                          ),
                        ),

                        // Dot indicators — centered between like and verified
                        Expanded(
                          child: images.length > 1
                              ? Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      images.length.clamp(0, 6),
                                      (i) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        width: _currentImage == i ? 18 : 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: _currentImage == i
                                              ? AppColors.primary
                                              : Colors.white.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: _currentImage == i
                                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 4)]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        ),

                        // Verified badge — bottom right
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 13, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Verified', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Info section ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        property.priceFormatted,
                        style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      if (property.priceSuffix.isNotEmpty) ...[
                        const SizedBox(width: 3),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            property.priceSuffix,
                            style: TextStyle(color: context.textSecColor, fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    property.title,
                    style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Location + optional distance pill
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(color: context.textSecColor, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.distanceLabel != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.primarySurfColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me_rounded, size: 10, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                widget.distanceLabel!,
                                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 0.5, color: context.divColor),
                  const SizedBox(height: 10),
                  // Features row
                  Row(
                    children: [
                      if (property.type != PropertyType.plot) ...[
                        if (property.bedrooms > 0) ...[
                          const Icon(Icons.bed_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('${property.bedrooms} beds', style: TextStyle(color: context.textSecColor, fontSize: 12)),
                          const SizedBox(width: 14),
                        ],
                        if (property.bathrooms > 0) ...[
                          const Icon(Icons.bathtub_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('${property.bathrooms} baths', style: TextStyle(color: context.textSecColor, fontSize: 12)),
                          const SizedBox(width: 14),
                        ],
                        if (property.hasParking) ...[
                          const Icon(Icons.local_parking_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Parking', style: TextStyle(color: context.textSecColor, fontSize: 12)),
                          const SizedBox(width: 14),
                        ],
                        if (property.hasWifi) ...[
                          const Icon(Icons.wifi_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('WiFi', style: TextStyle(color: context.textSecColor, fontSize: 12)),
                        ],
                      ],
                      if (property.plotSize != null) ...[
                        const Icon(Icons.aspect_ratio_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(property.plotSize!, style: TextStyle(color: context.textSecColor, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Property Slide Card (featured horizontal carousel) ───────────────────────

class PropertySlideCard extends ConsumerWidget {
  final PropertyModel property;

  const PropertySlideCard({super.key, required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final isLiked = user != null && property.likedBy.contains(user.id);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.propertyDetailPath(property.id)),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              PropertyImageWidget(
                path: property.images.isNotEmpty ? property.images.first : '',
                width: double.infinity,
                height: 200,
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    if (user != null) {
                      ref.read(propertyProvider.notifier).toggleLike(property.id, user.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isLiked ? Colors.red : Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.white : Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                    if (property.reviewCount > 0)
                      Text(
                        '${property.reviewCount} Reviews',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: AppColors.star, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        property.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
