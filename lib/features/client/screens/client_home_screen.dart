import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/constants/app_strings.dart';
import 'package:taftaf/core/models/ad_model.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/core/services/location_service.dart';
import 'package:taftaf/features/ads/widgets/property_ad_overlay.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';
import 'package:taftaf/shared/widgets/property_card.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _locationSvc = LocationService();
  Position? _userPosition;
  bool _isLoadingLocation = false;

  // Ad state
  List<AdWithProperty> _activeAds = [];
  bool _isAdShowing = false;
  AdWithProperty? _currentAd;
  DateTime? _lastAdShownAt;
  static const _adCooldown = Duration(seconds: 45);
  static const _minScrollForFirstAd = 600.0;
  static final _rng = Random();

  // Cached derived data — only recomputed when inputs change
  List<AdWithProperty> _cachedEligibleAds = [];
  bool _eligibleAdsDirty = true;                    // invalidated on ads-load or location change
  List<MapEntry<PropertyModel, double>> _cachedNearby = [];
  List<PropertyModel>? _lastNearbyProps;
  Position? _lastNearbyPos;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(propertyProvider.notifier).loadAll();
      _fetchUserLocation();
      _loadAds();
    });
  }

  Future<void> _loadAds() async {
    final ads = await ref.read(propertyServiceProvider).fetchAdsWithProperties();
    if (mounted) setState(() { _activeAds = ads; _eligibleAdsDirty = true; });
  }

  // Houses/apartments are geo-gated to within 15 km; other types always shown.
  // Fails open when location is unavailable — no ads are silently dropped.
  // Result is cached; _eligibleAdsDirty forces a recompute after ads or location change.
  List<AdWithProperty> _eligibleAds() {
    if (!_eligibleAdsDirty) return _cachedEligibleAds;
    const geoTypes = {PropertyType.house, PropertyType.apartment};
    const radiusMeters = 15000.0;
    _cachedEligibleAds = _activeAds.where((adw) {
      if (!adw.ad.isActive) return false;
      final prop = adw.property;
      if (!geoTypes.contains(prop.type)) return true;
      if (_userPosition == null || !prop.hasLocation) return true;
      final dist = Geolocator.distanceBetween(
        _userPosition!.latitude, _userPosition!.longitude,
        prop.latitude!, prop.longitude!,
      );
      return dist <= radiusMeters;
    }).toList();
    _eligibleAdsDirty = false;
    return _cachedEligibleAds;
  }

  void _onScroll() {
    if (_isAdShowing || _activeAds.isEmpty) return;
    if (_scrollCtrl.offset < _minScrollForFirstAd) return;
    if (_lastAdShownAt != null &&
        DateTime.now().difference(_lastAdShownAt!) < _adCooldown) { return; }
    final eligible = _eligibleAds();   // returns cached list on subsequent scroll events
    if (eligible.isEmpty) return;
    final nextAd = eligible[_rng.nextInt(eligible.length)];
    setState(() {
      _currentAd = nextAd;
      _isAdShowing = true;
      _lastAdShownAt = DateTime.now();
    });
    ref.read(propertyProvider.notifier).incrementView(nextAd.property.id);
  }

  Future<void> _fetchUserLocation() async {
    setState(() => _isLoadingLocation = true);
    final pos = await _locationSvc.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPosition = pos;
        _isLoadingLocation = false;
        _eligibleAdsDirty = true;   // location changed — re-filter ads next time
      });
    }
  }

  List<MapEntry<PropertyModel, double>> _nearbyWithDist(List<PropertyModel> all) {
    final pos = _userPosition;
    if (pos == null) return [];
    final result = <MapEntry<PropertyModel, double>>[];
    for (final p in all) {
      if (!p.hasLocation) continue;
      final dist = _locationSvc.distanceBetweenKm(pos.latitude, pos.longitude, p.latitude!, p.longitude!);
      if (dist <= 15) result.add(MapEntry(p, dist));
    }
    result.sort((a, b) => a.value.compareTo(b.value));
    return result;
  }

  // Returns cached nearby list, recomputing only when the property list identity
  // or current position changes.
  List<MapEntry<PropertyModel, double>> _getNearby(List<PropertyModel> props) {
    if (identical(_lastNearbyProps, props) && identical(_lastNearbyPos, _userPosition)) {
      return _cachedNearby;
    }
    _lastNearbyProps = props;
    _lastNearbyPos = _userPosition;
    _cachedNearby = _nearbyWithDist(props);
    return _cachedNearby;
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final propState = ref.watch(propertyProvider);
    // Verified properties float to the top of all listings
    final properties = [...propState.filtered]..sort((a, b) {
        if (a.isVerified == b.isVerified) return 0;
        return a.isVerified ? -1 : 1;
      });
    // Featured carousel = verified only
    final featuredProperties = properties.where((p) => p.isVerified).toList();
    // Near you = within 15 km, sorted by distance (cached — not recomputed on every scroll)
    final nearbyWithDist = _getNearby(propState.properties);

    return Stack(
      children: [
      Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          _Header(user: user),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (q) => ref.read(propertyProvider.notifier).search(q),
                      onSearchTap: () => context.push(AppRoutes.search),
                    ),
                  ),
                  // Section title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      AppStrings.selectProperty,
                      style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        TealChip(
                          label: 'All',
                          icon: Icons.apps_rounded,
                          isSelected: propState.selectedType == null,
                          onTap: () => ref.read(propertyProvider.notifier).selectType(null),
                        ),
                        const SizedBox(width: 10),
                        TealChip(
                          label: AppStrings.airbnb,
                          icon: Icons.nightlife_rounded,
                          isSelected: propState.selectedType == PropertyType.airbnb,
                          onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.airbnb),
                        ),
                        const SizedBox(width: 10),
                        TealChip(
                          label: AppStrings.apartments,
                          icon: Icons.apartment_rounded,
                          isSelected: propState.selectedType == PropertyType.apartment,
                          onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.apartment),
                        ),
                        const SizedBox(width: 10),
                        TealChip(
                          label: AppStrings.plotsLand,
                          icon: Icons.terrain_rounded,
                          isSelected: propState.selectedType == PropertyType.plot,
                          onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.plot),
                        ),
                        const SizedBox(width: 10),
                        TealChip(
                          label: AppStrings.housesRent,
                          icon: Icons.house_rounded,
                          isSelected: propState.selectedType == PropertyType.house,
                          onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.house),
                        ),
                        const SizedBox(width: 10),
                        TealChip(
                          label: 'Commercial',
                          icon: Icons.store_rounded,
                          isSelected: propState.selectedType == PropertyType.commercial,
                          onTap: () => ref.read(propertyProvider.notifier).selectType(PropertyType.commercial),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Featured carousel — verified properties only
                  if (propState.searchQuery.isEmpty &&
                      propState.selectedType == null &&
                      (propState.isLoading || featuredProperties.isNotEmpty)) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 12),
                      child: Row(
                        children: [
                          Text(
                            'FEATURED PROPERTIES',
                            style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 210,
                      child: propState.isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 16),
                              itemCount: featuredProperties.length,
                              itemBuilder: (_, i) =>
                                  PropertySlideCard(property: featuredProperties[i])
                                      .animate()
                                      .fadeIn(delay: (i * 100).ms)
                                      .slideX(begin: 0.2),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Near You section — visible when location is available
                  if (_isLoadingLocation || nearbyWithDist.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'NEAR YOU',
                            style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 220,
                      child: _isLoadingLocation
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 16),
                              itemCount: nearbyWithDist.length,
                              itemBuilder: (_, i) {
                                final entry = nearbyWithDist[i];
                                return _NearYouCard(
                                  property: entry.key,
                                  distance: _locationSvc.formatDistance(entry.value),
                                ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.15);
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Property listing header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'PROPERTY LISTINGS',
                          style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
                        ),
                        const Spacer(),
                        Icon(Icons.filter_list_rounded, color: context.textSecColor, size: 20),
                      ],
                    ),
                  ),
                  // Property list
                  if (propState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [PropertyCardShimmer(), PropertyCardShimmer(), PropertyCardShimmer()],
                      ),
                    )
                  else if (properties.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No properties found',
                          style: TextStyle(color: context.textSecColor, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          for (var i = 0; i < properties.length; i++)
                            PropertyListCard(property: properties[i])
                                .animate()
                                .fadeIn(delay: (i * 80).ms)
                                .slideY(begin: 0.1),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 0),
    ),
      // Ad overlay — covers full screen, blocks scroll while countdown runs
      if (_isAdShowing && _currentAd != null)
        PropertyAdOverlay(
          key: ValueKey(_currentAd!.ad.id),
          adWithProperty: _currentAd!,
          onDismiss: () => setState(() {
            _isAdShowing = false;
            _currentAd = null;
          }),
        ),
    ],
    );
  }
}

// ── Near You card ─────────────────────────────────────────────────────────────

class _NearYouCard extends StatelessWidget {
  final PropertyModel property;
  final String distance;

  const _NearYouCard({required this.property, required this.distance});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.propertyDetailPath(property.id)),
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PropertyImageWidget(
                path: property.images.isNotEmpty ? property.images.first : '',
                width: double.infinity,
                height: 220,
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
                    ),
                  ),
                ),
              ),
              // Distance badge — top left
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.primarySurfColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, size: 10, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              // Title + price at bottom
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${property.priceFormatted}${property.priceSuffix}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final dynamic user;
  const _Header({this.user});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _firstName {
    final name = user?.username as String? ?? 'User';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/bg_home.jpg', fit: BoxFit.cover, alignment: Alignment.center),
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
                GestureDetector(
                  onTap: () => context.push(AppRoutes.notifications),
                  child: Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_rounded, color: context.textColor, size: 22),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.profile),
                  child: UserAvatarWidget(
                    profilePic: user?.profilePic as String?,
                    displayName: user?.username as String? ?? 'U',
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

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearchTap;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.divColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                hintStyle: TextStyle(color: context.textMutedColor, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.search, color: AppColors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
