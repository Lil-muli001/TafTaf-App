import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/core/services/view_service.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taftaf/core/providers/call_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  late final PageController _pageCtrl;
  late final ScrollController _thumbCtrl;
  int _currentImage = 0;

  bool _hasPaid = false;
  bool _checkingPayment = true;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _thumbCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkViewStatus();
    });
  }

  Future<void> _checkViewStatus() async {
    final user = ref.read(authProvider).currentUser;
    // Owners always see for free
    if (user == null || user.isOwner) {
      if (mounted) setState(() { _hasPaid = true; _checkingPayment = false; });
      return;
    }
    final viewed = await ViewService().hasViewed(user.id, widget.propertyId);
    if (mounted) setState(() { _hasPaid = viewed; _checkingPayment = false; });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _thumbCtrl.dispose();
    super.dispose();
  }

  PropertyModel? _findProperty() {
    final props = ref.read(propertyProvider).properties;
    try {
      return props.firstWhere((p) => p.id == widget.propertyId);
    } catch (_) {
      return null;
    }
  }

  void _onPageChanged(int i, int total) {
    HapticFeedback.selectionClick();
    setState(() => _currentImage = i);
    const thumbW = 62.0;
    final target = (i * thumbW) - (MediaQuery.of(context).size.width / 2) + thumbW / 2;
    if (_thumbCtrl.hasClients) {
      _thumbCtrl.animateTo(
        target.clamp(0.0, _thumbCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openGallery(List<String> images) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _FullScreenGallery(images: images, initialIndex: _currentImage),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _initiateVoiceCall(PropertyModel property) async {
    final user = ref.read(authProvider).currentUser;
    if (user == null) return;

    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice calls.'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    ref.read(callProvider.notifier).startCall(
      callerId: user.id,
      callerName: user.username,
      calleeId: property.ownerId,
      calleeName: property.ownerName,
    );
  }

  Future<void> _contactOwner(PropertyModel property) async {
    final user = ref.read(authProvider).currentUser;
    if (user == null) return;
    final chat = await ref.read(chatProvider.notifier).findOrCreateChat(
          userId: user.id,
          userName: user.username,
          ownerId: property.ownerId,
          ownerName: property.ownerName,
          propertyId: property.id,
          propertyTitle: property.title,
        );
    if (!mounted) return;
    context.push(AppRoutes.chatRoomPath(chat.id), extra: {'title': property.title});
  }

  @override
  Widget build(BuildContext context) {
    final property = _findProperty();
    final user = ref.watch(authProvider).currentUser;

    if (property == null) {
      return Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(backgroundColor: context.bgColor),
        body: Center(
          child: Text('Property not found', style: TextStyle(color: context.textSecColor)),
        ),
      );
    }

    final isLiked = user != null && property.likedBy.contains(user.id);
    final isOwner = user?.id == property.ownerId;
    // Owner-role users must never see client CTAs (book/chat/like) on other properties.
    final isClientRole = !(user?.isOwner ?? false);
    final images = property.images;
    final hasMany = images.length > 1;

    // ── Build the main scrollable content ────────────────────────────────────
    final detailScroll = CustomScrollView(
      slivers: [
        // ── Hero image slideshow ─────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: context.cardColor,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: Icon(Icons.arrow_back, color: context.textColor),
            ),
          ),
          actions: [
            if (hasMany)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.center,
                child: Text(
                  '${_currentImage + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            if (!isOwner && isClientRole)
              GestureDetector(
                onTap: () {
                  if (user != null) ref.read(propertyProvider.notifier).toggleLike(property.id, user.id);
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.redAccent : Colors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openGallery(images),
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: images.length,
                      onPageChanged: (i) => _onPageChanged(i, images.length),
                      itemBuilder: (_, i) => PropertyImageWidget(path: images[i], fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    color: context.surfaceColor,
                    child: Center(child: Icon(Icons.home_rounded, color: context.textSecColor, size: 80)),
                  ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xEE0A1628)],
                      ),
                    ),
                  ),
                ),
                if (hasMany)
                  Positioned(
                    bottom: 14, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((e) {
                        final active = e.key == _currentImage;
                        return GestureDetector(
                          onTap: () => _pageCtrl.animateToPage(
                            e.key,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: active
                                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.55), blurRadius: 8)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (images.isNotEmpty)
                  Positioned(
                    top: 56, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full_rounded, color: Colors.white70, size: 11),
                          SizedBox(width: 4),
                          Text('Fullscreen', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Thumbnail strip ──────────────────────────────────────────────────
        if (hasMany)
          SliverToBoxAdapter(
            child: Container(
              height: 72,
              color: context.cardColor,
              child: ListView.builder(
                controller: _thumbCtrl,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: images.length,
                itemBuilder: (_, i) {
                  final active = i == _currentImage;
                  return GestureDetector(
                    onTap: () => _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? AppColors.primary : Colors.white12, width: active ? 2 : 1),
                        boxShadow: active
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 6)]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: PropertyImageWidget(path: images[i], width: 54, height: 54, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // ── Property details ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + type badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: TextStyle(color: context.textColor, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: context.primarySurfColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(property.typeLabel, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 15),
                    const SizedBox(width: 4),
                    Text(property.location, style: TextStyle(color: context.textSecColor, fontSize: 14)),
                  ],
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 14),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      property.priceFormatted,
                      style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3, left: 2),
                      child: Text(property.priceSuffix, style: TextStyle(color: context.textSecColor, fontSize: 14)),
                    ),
                  ],
                ).animate().fadeIn(delay: 130.ms),

                // Rating
                if (property.rating > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < property.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.star,
                        size: 18,
                      )),
                      const SizedBox(width: 6),
                      Text(
                        '${property.rating} · ${property.reviewCount} reviews',
                        style: TextStyle(color: context.textSecColor, fontSize: 13),
                      ),
                    ],
                  ).animate().fadeIn(delay: 180.ms),
                ],
                const SizedBox(height: 22),

                // Feature chips
                if (property.type != PropertyType.plot) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (property.bedrooms > 0) _FeatureChip(icon: Icons.bed_outlined, label: '${property.bedrooms} Bed'),
                      if (property.bathrooms > 0) _FeatureChip(icon: Icons.bathtub_outlined, label: '${property.bathrooms} Bath'),
                      if (property.hasWifi) const _FeatureChip(icon: Icons.wifi_rounded, label: 'WiFi'),
                      if (property.hasParking) const _FeatureChip(icon: Icons.local_parking_rounded, label: 'Parking'),
                      if (property.hasPool) const _FeatureChip(icon: Icons.pool_rounded, label: 'Pool'),
                    ],
                  ).animate().fadeIn(delay: 230.ms),
                  const SizedBox(height: 20),
                ] else if (property.plotSize != null) ...[
                  _FeatureChip(icon: Icons.aspect_ratio_rounded, label: property.plotSize!),
                  const SizedBox(height: 20),
                ],

                // Description
                _SectionTitle('Description'),
                const SizedBox(height: 8),
                Text(
                  property.description,
                  style: TextStyle(color: context.textSecColor, fontSize: 14, height: 1.65),
                ).animate().fadeIn(delay: 280.ms),
                const SizedBox(height: 22),

                // Amenities
                if (property.amenities.isNotEmpty) ...[
                  _SectionTitle('Amenities'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: property.amenities
                        .map((a) => Chip(
                              label: Text(a, style: TextStyle(color: context.textColor, fontSize: 12)),
                              backgroundColor: context.primarySurfColor,
                              side: const BorderSide(color: AppColors.primary, width: 1),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ).animate().fadeIn(delay: 320.ms),
                  const SizedBox(height: 22),
                ],

                // Location & Map
                if (property.hasLocation) ...[
                  _SectionTitle('Location & Map'),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(property.latitude!, property.longitude!),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('property'),
                            position: LatLng(property.latitude!, property.longitude!),
                            infoWindow: InfoWindow(title: property.title),
                          ),
                        },
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        liteModeEnabled: true,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${property.latitude},${property.longitude}',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.primarySurfColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Get Directions',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // Owner card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.divColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          property.ownerName.isNotEmpty ? property.ownerName[0].toUpperCase() : 'O',
                          style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(property.ownerName, style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600)),
                            Text('Property Owner', style: TextStyle(color: context.textSecColor, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (!isOwner && isClientRole)
                        ElevatedButton.icon(
                          onPressed: () => _contactOwner(property),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 370.ms),
                const SizedBox(height: 24),

                // CTA buttons
                if (!isOwner && isClientRole) ...[
                  if (property.type == PropertyType.apartment ||
                      property.type == PropertyType.airbnb  ||
                      property.type == PropertyType.house) ...[
                    PrimaryButton(
                      label: property.type == PropertyType.airbnb ? 'Book Now' : 'Request Booking',
                      onTap: () => context.push(AppRoutes.bookProperty, extra: property),
                    ).animate().fadeIn(delay: 420.ms),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _initiateVoiceCall(property),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Voice Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _contactOwner(property),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                      label: const Text('Chat with Owner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ).animate().fadeIn(delay: 480.ms),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _initiateVoiceCall(property),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Voice Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ).animate().fadeIn(delay: 420.ms),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Contact Owner',
                      onTap: () => _contactOwner(property),
                    ).animate().fadeIn(delay: 450.ms),
                  ],
                ],

                if (isOwner)
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.addProperty, extra: property),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Listing'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ).animate().fadeIn(delay: 420.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );

    // ── Assemble with payment gate ────────────────────────────────────────────
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Blur content until payment is confirmed
          if (!_hasPaid)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: IgnorePointer(child: detailScroll),
            )
          else
            detailScroll,

          // Checking payment status
          if (_checkingPayment)
            Container(
              color: context.bgColor.withValues(alpha: 0.6),
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),

          // Viewing fee overlay
          if (!_checkingPayment && !_hasPaid)
            _ViewingFeeOverlay(
              property: property,
              onPaid: () async {
                final u = ref.read(authProvider).currentUser;
                if (u != null) {
                  await ViewService().markAsViewed(u.id, property.id);
                  await ref.read(propertyProvider.notifier).incrementView(property.id);
                }
                if (mounted) setState(() => _hasPaid = true);
              },
              onBack: () => context.pop(),
            ),
        ],
      ),
    );
  }
}

// ── Viewing Fee Overlay ───────────────────────────────────────────────────────

class _ViewingFeeOverlay extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback onPaid;
  final VoidCallback onBack;

  const _ViewingFeeOverlay({
    required this.property,
    required this.onPaid,
    required this.onBack,
  });

  @override
  State<_ViewingFeeOverlay> createState() => _ViewingFeeOverlayState();
}

class _ViewingFeeOverlayState extends State<_ViewingFeeOverlay> {
  bool _success = false;

  Future<void> _pay() async {
    final paid = await context.push<bool>(
      AppRoutes.mpesaPayment,
      extra: {
        'amount': 50,
        'description': 'Property Viewing Fee',
        'reference': 'TafTaf-View',
      },
    );
    if (paid != true || !mounted) return;
    setState(() => _success = true);
    await Future.delayed(const Duration(milliseconds: 700));
    widget.onPaid();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
      child: Container(
        color: Colors.black.withValues(alpha: 0.38),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),

              const Spacer(),

              // Property title hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  widget.property.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Glass card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lock icon
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Container(
                              key: ValueKey(_success),
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: _success
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : context.primarySurfColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: _success ? 0.6 : 0.35),
                                ),
                              ),
                              child: Icon(
                                _success ? Icons.lock_open_rounded : Icons.lock_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Heading
                          Text(
                            _success ? 'Unlocked!' : 'Unlock Property Details',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pay once to access the full details\nfor this property — forever.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.55),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),

                          // Benefits
                          ...[
                            (Icons.contact_phone_rounded, 'Owner contact info'),
                            (Icons.map_rounded, 'Exact location & directions map'),
                            (Icons.chat_bubble_rounded, 'Direct chat with the owner'),
                            (Icons.checklist_rounded, 'Full amenities & specifications'),
                          ].map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: context.primarySurfColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.$1, color: AppColors.primary, size: 14),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.$2,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 22),

                          // Fee pill
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Viewing Fee  ', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
                                const Text('KES 50', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800)),
                                Text('  · One-time', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Pay button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _success ? null : _pay,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _success ? AppColors.success : AppColors.primary,
                                foregroundColor: AppColors.black,
                                disabledBackgroundColor: _success ? AppColors.success : AppColors.primary.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _success
                                        ? const Row(
                                            key: ValueKey('success'),
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('Payment Successful', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                                            ],
                                          )
                                        : const Text(
                                            key: ValueKey('pay'),
                                            'Pay KES 50 via M-Pesa',
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full-screen gallery ───────────────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) {
          HapticFeedback.selectionClick();
          setState(() => _current = i);
        },
        itemBuilder: (_, i) {
          final path = widget.images[i];
          return InteractiveViewer(
            minScale: 0.9,
            maxScale: 5.0,
            child: Center(
              child: path.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: path,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      ),
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                    )
                  : Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w700),
      );
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: context.textColor, fontSize: 13)),
        ],
      ),
    );
  }
}
