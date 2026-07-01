import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/features/ads/widgets/cinematic_image.dart';
import 'package:taftaf/core/models/ad_model.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';

class OwnerHomeScreen extends ConsumerStatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  ConsumerState<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends ConsumerState<OwnerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      if (user != null) ref.read(propertyProvider.notifier).loadByOwner(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final propState = ref.watch(propertyProvider);
    final props = propState.properties;

    final totalViews = props.fold(0, (sum, p) => sum + p.viewCount);
    final totalSaves = props.fold(0, (sum, p) => sum + p.likedBy.length);
    final ownerAds = ref.watch(adProvider).where((a) => a.ownerId == (user?.id ?? '')).toList();
    final activeAdsCount = ownerAds.length;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: _Header(user: user)),

          // ── Stats 2×2 grid ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total',
                          value: '${props.length}',
                          icon: Icons.home_rounded,
                          iconBg: context.primarySurfColor,
                          iconColor: AppColors.primary,
                        ).animate().fadeIn(delay: 0.ms),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Total Views',
                          value: '$totalViews',
                          icon: Icons.visibility_rounded,
                          iconBg: const Color(0xFF0D1A33),
                          iconColor: const Color(0xFF4D9FFF),
                        ).animate().fadeIn(delay: 80.ms),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Saves',
                          value: '$totalSaves',
                          icon: Icons.favorite_rounded,
                          iconBg: const Color(0xFF2E0D1A),
                          iconColor: const Color(0xFFFF6B8A),
                        ).animate().fadeIn(delay: 160.ms),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Ad Manager',
                          value: '$activeAdsCount',
                          icon: Icons.campaign_rounded,
                          iconBg: AppColors.primarySurface,
                          iconColor: AppColors.primary,
                          onTap: () => _showAdManagerSheet(context),
                        ).animate().fadeIn(delay: 240.ms),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Category filter chips ─────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    isSelected: propState.selectedType == null,
                    onTap: () => ref.read(propertyProvider.notifier).selectType(null),
                  ),
                  _CategoryChip(
                    label: 'Plots/Land',
                    icon: Icons.terrain_rounded,
                    isSelected: propState.selectedType == PropertyType.plot,
                    onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.plot),
                  ),
                  _CategoryChip(
                    label: 'Apartments',
                    icon: Icons.apartment_rounded,
                    isSelected: propState.selectedType == PropertyType.apartment,
                    onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.apartment),
                  ),
                  _CategoryChip(
                    label: 'Houses',
                    icon: Icons.house_rounded,
                    isSelected: propState.selectedType == PropertyType.house,
                    onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.house),
                  ),
                  _CategoryChip(
                    label: 'Airbnb',
                    icon: Icons.nightlife_rounded,
                    isSelected: propState.selectedType == PropertyType.airbnb,
                    onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.airbnb),
                  ),
                  _CategoryChip(
                    label: 'Commercial',
                    icon: Icons.store_rounded,
                    isSelected: propState.selectedType == PropertyType.commercial,
                    onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.commercial),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── MY PROPERTIES header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'MY PROPERTIES',
                    style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  Icon(Icons.filter_list_rounded, color: context.textSecColor, size: 20),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Property list ─────────────────────────────────────────────
          if (propState.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [PropertyCardShimmer(), PropertyCardShimmer(), PropertyCardShimmer()]),
              ),
            )
          else if (propState.filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.home_outlined, color: context.textSecColor.withValues(alpha: 0.5), size: 72),
                    const SizedBox(height: 16),
                    Text(
                      'No properties yet.\nTap + to add your first listing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecColor, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(label: '+ Add Property', width: 180, onTap: () => context.push(AppRoutes.addProperty)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _OwnerPropertyCard(property: propState.filtered[i])
                      .animate()
                      .fadeIn(delay: (i * 60).ms)
                      .slideY(begin: 0.1, end: 0),
                ),
                childCount: propState.filtered.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 0),
    );
  }

  void _showAdManagerSheet(BuildContext context) {
    final ownerId = ref.read(authProvider).currentUser?.id ?? '';
    final ads = ref.read(adProvider).where((a) => a.ownerId == ownerId).toList();
    final props = ref.read(propertyProvider).properties;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AdManagerSheet(ads: ads, properties: props, ownerId: ownerId),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final dynamic user;
  const _Header({this.user});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _firstName {
    final name = user?.username as String? ?? 'Owner';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref
        .watch(notificationsProvider)
        .where((n) => !n.isRead)
        .length;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/bg_owner.jpg', fit: BoxFit.cover, alignment: Alignment.center),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xCC061420), Color(0xAA0D2137)],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: const TextStyle(color: Color(0xFFB0C4DE), fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _firstName,
                      style: const TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              // Notification bell with dynamic unread badge
              GestureDetector(
                onTap: () => context.push(AppRoutes.notifications),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_rounded, color: AppColors.white, size: 22),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              GestureDetector(
                onTap: () => context.push(AppRoutes.profile),
                child: UserAvatarWidget(
                  profilePic: user?.profilePic as String?,
                  displayName: user?.username as String? ?? 'O',
                  radius: 21,
                ),
              ),
            ],
          ),
        ),
      ),
      ],
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tappable ? AppColors.primary.withValues(alpha: 0.28) : context.divColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 20)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: context.textSecColor, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (tappable)
            Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
        ],
      ),
    );
    if (!tappable) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ── Category Chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isSelected ? AppColors.primary : context.divColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.black : context.textSecColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : context.textSecColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Owner Property Card ──────────────────────────────────────────────────────

class _OwnerPropertyCard extends ConsumerWidget {
  final PropertyModel property;
  const _OwnerPropertyCard({required this.property});

  String get _statusLabel {
    if (!property.isAvailable) return 'Unavailable';
    if (property.type == PropertyType.plot || property.priceType == PriceType.fixed) return 'For Sale';
    if (property.type == PropertyType.airbnb) return 'Active';
    return 'Rented';
  }

  Color get _statusColor {
    switch (_statusLabel) {
      case 'For Sale': return AppColors.success;
      case 'Active': return AppColors.primary;
      case 'Rented': return const Color(0xFF4D9FFF);
      default: return AppColors.textMuted;
    }
  }

  Color get _statusBg {
    switch (_statusLabel) {
      case 'For Sale': return const Color(0xFF0D3320);
      case 'Active': return AppColors.primarySurface;
      case 'Rented': return const Color(0xFF0D1A33);
      default: return AppColors.surface;
    }
  }

  String get _subLabel {
    if (property.type == PropertyType.plot) return property.plotSize ?? 'Plot/Land';
    if (property.type == PropertyType.apartment) return '${property.bedrooms} Units';
    if (property.bedrooms > 0) return '${property.bedrooms} Bed · ${property.bathrooms} Bath';
    return property.typeLabel;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(adProvider);
    final matches = ads.where((a) => a.propertyId == property.id && a.isActive);
    final activeBoost = matches.isEmpty ? null : matches.first;
    final isBoosted = activeBoost != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divColor),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            child: PropertyImageWidget(
              path: property.images.isNotEmpty ? property.images.first : '',
              width: 110,
              height: 110,
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(10)),
                        child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      if (isBoosted) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 9, color: AppColors.primary),
                              SizedBox(width: 2),
                              Text('Ad Live', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 12, color: context.textMutedColor),
                      const SizedBox(width: 3),
                      Text(_subLabel, style: TextStyle(color: context.textMutedColor, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: context.textMutedColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(color: context.textMutedColor, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 12, color: const Color(0xFF4D9FFF)),
                      const SizedBox(width: 3),
                      Text(
                        '${property.viewCount} views',
                        style: const TextStyle(color: Color(0xFF4D9FFF), fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.favorite_rounded, size: 12, color: const Color(0xFFFF6B8A)),
                      const SizedBox(width: 3),
                      Text(
                        '${property.likedBy.length} saves',
                        style: const TextStyle(color: Color(0xFFFF6B8A), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '${property.priceFormatted}${property.priceSuffix}',
                        style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showManageSheet(context, ref, activeBoost),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Manage', style: TextStyle(color: AppColors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageSheet(BuildContext context, WidgetRef ref, AdModel? activeBoost) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ManageSheet(
        property: property,
        ref: ref,
        activeBoost: activeBoost,
        onVerifyTap: property.isVerified
            ? null
            : () => _showVerifyPaymentSheet(context, ref),
        onBoostTap: () => _showAdvertiseSheet(context, ref),
      ),
    );
  }

  void _showAdvertiseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _AdvertiseSheet(property: property, ref: ref),
    );
  }

  void _showVerifyPaymentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _VerifyPaymentSheet(property: property, ref: ref),
    );
  }
}

// ── Manage Bottom Sheet ──────────────────────────────────────────────────────

class _ManageSheet extends StatelessWidget {
  final PropertyModel property;
  final WidgetRef ref;
  final AdModel? activeBoost;
  final VoidCallback? onVerifyTap;
  final VoidCallback? onBoostTap;
  const _ManageSheet({
    required this.property,
    required this.ref,
    this.activeBoost,
    this.onVerifyTap,
    this.onBoostTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(property.title, style: const TextStyle(color: Color(0xFF8CBB00), fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          _SheetOption(
            icon: Icons.visibility_rounded,
            label: 'View Property',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.propertyDetailPath(property.id));
            },
          ),
          _SheetOption(
            icon: Icons.edit_rounded,
            label: 'Edit Property',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addProperty, extra: property);
            },
          ),
          if (activeBoost != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active Ad  ·  ${AdModel.packageName(activeBoost!.package)}',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('${AdModel.formatRemaining(activeBoost!.remaining)} remaining',
                            style: TextStyle(color: context.textMutedColor, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Live', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            )
          else
            _SheetOption(
              icon: Icons.campaign_rounded,
              label: 'Advertise  ·  KES 50 / week',
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 300), () => onBoostTap?.call());
              },
            ),
          _SheetOption(
            icon: property.isAvailable ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
            label: property.isAvailable ? 'Mark Unavailable' : 'Mark Available',
            onTap: () {
              Navigator.pop(context);
              ref.read(propertyProvider.notifier).updateProperty(property.copyWith(isAvailable: !property.isAvailable));
            },
          ),
          if (!property.isVerified)
            _SheetOption(
              icon: Icons.verified_rounded,
              label: 'Verify This Listing  ·  KES 50',
              onTap: () {
                Navigator.pop(context);
                Future.delayed(
                  const Duration(milliseconds: 300),
                  () => onVerifyTap?.call(),
                );
              },
            ),
          _SheetOption(
            icon: Icons.delete_rounded,
            label: 'Delete Property',
            color: const Color(0xFF8CBB00),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: ctx.surfaceColor,
                  title: Text('Delete Property', style: TextStyle(color: ctx.textColor)),
                  content: Text('Delete "${property.title}"? This cannot be undone.', style: TextStyle(color: ctx.textSecColor)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(propertyProvider.notifier).deleteProperty(property.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetOption({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    // icon always lime; text stays theme-aware unless an explicit color override is passed (e.g. Delete)
    final iconColor = color ?? AppColors.primary;
    final textColor = color ?? context.textColor;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: context.textSecColor, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Verify Payment Sheet ─────────────────────────────────────────────────────

class _VerifyPaymentSheet extends StatefulWidget {
  final PropertyModel property;
  final WidgetRef ref;
  const _VerifyPaymentSheet({required this.property, required this.ref});

  @override
  State<_VerifyPaymentSheet> createState() => _VerifyPaymentSheetState();
}

class _VerifyPaymentSheetState extends State<_VerifyPaymentSheet> {
  bool _isProcessing = false;

  Future<void> _pay() async {
    final paid = await context.push<bool>(
      AppRoutes.mpesaPayment,
      extra: {
        'amount': 50,
        'description': 'Listing Verification Fee',
        'reference': 'TafTaf-Verify',
      },
    );
    if (paid != true || !mounted) return;
    setState(() => _isProcessing = true);
    await widget.ref.read(propertyProvider.notifier).verifyProperty(widget.property.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Listing verified! Badge is now live for clients.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: context.primarySurfColor, shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35))),
            child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text('Verify This Listing', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            widget.property.title,
            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ...[
            'Verified badge shown on your listing',
            'Priority placement in search results',
            'Featured in the "Featured Properties" carousel',
          ].map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                const SizedBox(width: 10),
                Text(b, style: TextStyle(color: context.textSecColor, fontSize: 13)),
              ],
            ),
          )),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.primarySurfColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Verification Fee', style: TextStyle(color: context.textSecColor, fontSize: 13)),
                    Text('One-time fee', style: TextStyle(color: context.textMutedColor, fontSize: 11)),
                  ]),
                ),
                Text('KES 50', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _isProcessing ? 'Verifying...' : 'Pay KES 50 via M-Pesa',
            isLoading: _isProcessing,
            onTap: _isProcessing ? null : _pay,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.textSecColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Advertise Sheet ──────────────────────────────────────────────────────────

class _AdvertiseSheet extends StatefulWidget {
  final PropertyModel property;
  final WidgetRef ref;
  const _AdvertiseSheet({required this.property, required this.ref});

  @override
  State<_AdvertiseSheet> createState() => _AdvertiseSheetState();
}

class _AdvertiseSheetState extends State<_AdvertiseSheet> {
  int _step = 0;
  AdPackage _selected = AdPackage.monthly;
  bool _isProcessing = false;

  Future<void> _pay() async {
    final paid = await context.push<bool>(
      AppRoutes.mpesaPayment,
      extra: {
        'amount': AdModel.packagePrice(_selected),
        'description': 'Property Ad · ${AdModel.packageName(_selected)}',
        'reference': 'TafTaf-Ad',
      },
    );
    if (paid != true || !mounted) return;
    setState(() => _isProcessing = true);
    await widget.ref.read(adProvider.notifier).boostProperty(
      propertyId: widget.property.id,
      ownerId: widget.property.ownerId,
      package: _selected,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Ad for "${widget.property.title}" is live for ${AdModel.packageDurationLabel(_selected)}!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        child: _step == 0 ? _buildPreviewStep(context) : _buildPlanStep(context),
      ),
    );
  }

  Widget _buildPreviewStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Your Ad', style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('Preview how clients will see it', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AdPreviewCard(property: widget.property),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Auto-created from your photos — no manual design needed.',
                style: TextStyle(color: context.textSecColor, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.textSecColor, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildPlanStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.divColor),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: context.textColor),
              ),
            ),
            const SizedBox(width: 12),
            Text('Choose Your Plan', style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 16),
        ...[
          'Reaches all clients browsing the app',
          'Full-screen immersive display with your photos',
          'Auto-cancels when your plan expires',
        ].map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 11, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(b, style: TextStyle(color: context.textSecColor, fontSize: 12)),
            ],
          ),
        )),
        const SizedBox(height: 8),
        ...AdPackage.values.map((pkg) => _PlanTile(
          package: pkg,
          isSelected: _selected == pkg,
          onTap: () => setState(() => _selected = pkg),
        )),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Publish Ad · KES ${AdModel.packagePrice(_selected)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.textSecColor, fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Ad Preview Card ──────────────────────────────────────────────────────────

class _AdPreviewCard extends StatelessWidget {
  final PropertyModel property;
  const _AdPreviewCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final imagePath = property.images.isNotEmpty ? property.images.first : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CinematicImage(path: imagePath, width: double.infinity, height: 200, grain: true, vignette: true, letterbox: true),
            // Cinematic gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x30000000), Color(0xD8000000)],
                    stops: [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Lime left strip
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00BEFF0A), Color(0xFFBEFF0A), Color(0x00BEFF0A)],
                  ),
                ),
              ),
            ),
            // SPONSORED badge
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 10)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 10, color: AppColors.black),
                    SizedBox(width: 3),
                    Text('SPONSORED', style: TextStyle(color: AppColors.black, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.9)),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2200.ms, color: Colors.white.withValues(alpha: 0.22)),
            ),
            // Bottom content
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(property.priceFormatted, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                        if (property.priceSuffix.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 3, bottom: 1),
                            child: Text(property.priceSuffix, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(9)),
                          child: const Text('View Property', style: TextStyle(color: AppColors.black, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan Tile ────────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  final AdPackage package;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlanTile({required this.package, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMonthly = package == AdPackage.monthly;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : context.divColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(color: isSelected ? AppColors.primary : context.divColor, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, size: 13, color: AppColors.black) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AdModel.packageName(package),
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : context.textColor,
                          fontWeight: FontWeight.w700, fontSize: 14,
                        ),
                      ),
                      if (isMonthly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                          child: const Text('BEST VALUE', style: TextStyle(color: AppColors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                  Text(AdModel.packageReachLabel(package), style: TextStyle(color: context.textMutedColor, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KES ${AdModel.packagePrice(package)}',
                  style: TextStyle(color: isSelected ? AppColors.primary : context.textColor, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(AdModel.packageDurationLabel(package), style: TextStyle(color: context.textMutedColor, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ad Manager Sheet ─────────────────────────────────────────────────────────

class _AdManagerSheet extends StatelessWidget {
  final List<AdModel> ads;
  final List<PropertyModel> properties;
  final String ownerId;

  const _AdManagerSheet({
    required this.ads,
    required this.properties,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: ads.isEmpty ? 0.45 : 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                          ),
                          child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ad Manager', style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.w700)),
                              Text(
                                ads.isEmpty ? 'No active ads' : '${ads.length} active ad${ads.length == 1 ? '' : 's'}',
                                style: TextStyle(color: context.textMutedColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (ads.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D3320),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 7, color: AppColors.success),
                                SizedBox(width: 5),
                                Text('Live', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(color: context.divColor, height: 1),
                  ],
                ),
              ),
              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: ads.isEmpty
                    ? _buildEmpty(context)
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: ads.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final ad = ads[i];
                          final match = properties.where((p) => p.id == ad.propertyId);
                          return _AdCard(ad: ad, property: match.isNotEmpty ? match.first : null);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text('No Active Ads', style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Open "Manage" on any property and tap "Advertise" to boost its reach.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecColor, fontSize: 13, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ad Card ──────────────────────────────────────────────────────────────────

class _AdCard extends StatefulWidget {
  final AdModel ad;
  final PropertyModel? property;
  const _AdCard({required this.ad, this.property});

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.ad.remaining;
    final total = AdModel.packageDuration(widget.ad.package);
    final progress = (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final progressColor = progress > 0.5
        ? AppColors.primary
        : progress > 0.2
            ? const Color(0xFFFFB347)
            : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: PropertyImageWidget(
                  path: widget.property?.images.isNotEmpty == true ? widget.property!.images.first : '',
                  width: 56, height: 56,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property?.title ?? 'Property',
                      style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            AdModel.packageName(widget.ad.package),
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF0D3320), borderRadius: BorderRadius.circular(8)),
                          child: const Text('LIVE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Impressions counter
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${widget.ad.impressions}', style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('impressions', style: TextStyle(color: context.textMutedColor, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time remaining row
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: context.textMutedColor),
              const SizedBox(width: 5),
              Text(
                '${AdModel.formatRemaining(remaining)} left',
                style: TextStyle(color: context.textSecColor, fontSize: 11),
              ),
              const Spacer(),
              Text(
                AdModel.packageDurationLabel(widget.ad.package),
                style: TextStyle(color: context.textMutedColor, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: context.divColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
