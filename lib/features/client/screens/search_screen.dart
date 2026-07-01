import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/services/location_service.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/location_autocomplete_field.dart';
import 'package:taftaf/shared/widgets/property_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _locationSvc = LocationService();

  PropertyType? _selectedType;

  // GPS-based Near Me
  bool _sortByDistance = false;
  bool _fetchingLocation = false;
  Position? _userPosition;

  // Area search (from autocomplete)
  double? _areaLat;
  double? _areaLng;

  // Radius filter — applies to both Near Me and area mode
  bool _filterByRadius = false;
  double _radiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(propertyProvider.notifier).loadAll();
    });
    _locationCtrl.addListener(_onLocationTextChanged);
  }

  void _onLocationTextChanged() {
    if (_locationCtrl.text.isEmpty && (_areaLat != null || _areaLng != null)) {
      setState(() {
        _areaLat = null;
        _areaLng = null;
        _filterByRadius = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _locationCtrl.removeListener(_onLocationTextChanged);
    _locationCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _enableNearMe() async {
    setState(() => _fetchingLocation = true);
    final pos = await _locationSvc.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPosition = pos;
        _sortByDistance = pos != null;
        _fetchingLocation = false;
        if (pos != null) {
          _areaLat = null;
          _areaLng = null;
          _locationCtrl.clear();
          _filterByRadius = false;
        }
      });
    }
  }

  void _onAreaLocationSelected(String address, double lat, double lng) {
    setState(() {
      _areaLat = lat;
      _areaLng = lng;
      _filterByRadius = true;
      _radiusKm = 10.0;
      _sortByDistance = false;
    });
  }

  bool get _hasActiveCenter =>
      (_sortByDistance && _userPosition != null) ||
      (_areaLat != null && _areaLng != null);

  double? get _centerLat =>
      _sortByDistance && _userPosition != null
          ? _userPosition!.latitude
          : _areaLat;

  double? get _centerLng =>
      _sortByDistance && _userPosition != null
          ? _userPosition!.longitude
          : _areaLng;

  List<PropertyModel> get _filtered {
    var list = ref.read(propertyProvider).properties;

    // Text search
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }

    // Type filter
    if (_selectedType != null) {
      list = list.where((p) => p.type == _selectedType).toList();
    }

    // Price filter
    final minPrice =
        double.tryParse(_minPriceCtrl.text.replaceAll(',', '')) ?? 0;
    final maxPrice =
        double.tryParse(_maxPriceCtrl.text.replaceAll(',', ''));
    list = list
        .where((p) =>
            p.price >= minPrice &&
            (maxPrice == null || p.price <= maxPrice))
        .toList();

    // Radius filter
    final cLat = _centerLat;
    final cLng = _centerLng;
    if (_filterByRadius && cLat != null && cLng != null) {
      list = list.where((p) {
        if (!p.hasLocation) return true;
        final d = _locationSvc.distanceBetweenKm(
            cLat, cLng, p.latitude!, p.longitude!);
        return d <= _radiusKm;
      }).toList();
    }

    // Sort
    if (cLat != null && cLng != null) {
      list.sort((a, b) {
        if (!a.hasLocation && !b.hasLocation) return 0;
        if (!a.hasLocation) return 1;
        if (!b.hasLocation) return -1;
        final dA = _locationSvc.distanceBetweenKm(
            cLat, cLng, a.latitude!, a.longitude!);
        final dB = _locationSvc.distanceBetweenKm(
            cLat, cLng, b.latitude!, b.longitude!);
        return dA.compareTo(dB);
      });
    } else {
      list.sort((a, b) {
        if (a.isVerified == b.isVerified) return 0;
        return a.isVerified ? -1 : 1;
      });
    }
    return list;
  }

  String? _distanceLabel(PropertyModel p) {
    final cLat = _centerLat;
    final cLng = _centerLng;
    if (cLat == null || cLng == null || !p.hasLocation) return null;
    final d = _locationSvc.distanceBetweenKm(
        cLat, cLng, p.latitude!, p.longitude!);
    return _locationSvc.formatDistance(d);
  }

  @override
  Widget build(BuildContext context) {
    final propState = ref.watch(propertyProvider);
    final results = _filtered;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          'SEARCH PROPERTIES',
          style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5),
        ),
        backgroundColor: context.bgColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: context.divColor),
        ),
      ),
      body: Column(
        children: [
          // ── Text search ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              autofocus: true,
              style: TextStyle(color: context.textColor),
              decoration: InputDecoration(
                hintText: 'Search title, description...',
                hintStyle: TextStyle(color: context.textMutedColor),
                prefixIcon: Icon(Icons.search, color: context.textSecColor),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: context.textSecColor),
                        onPressed: () => setState(() => _searchCtrl.clear()),
                      )
                    : null,
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TealChip(
                  label: 'All',
                  isSelected: _selectedType == null &&
                      !_sortByDistance &&
                      _areaLat == null,
                  onTap: () => setState(() {
                    _selectedType = null;
                    _sortByDistance = false;
                    _areaLat = null;
                    _areaLng = null;
                    _filterByRadius = false;
                    _locationCtrl.clear();
                  }),
                ),
                const SizedBox(width: 8),
                // Near Me chip
                GestureDetector(
                  onTap: () async {
                    if (_sortByDistance) {
                      setState(
                          () => _sortByDistance = false);
                    } else {
                      await _enableNearMe();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _sortByDistance
                          ? AppColors.primary
                          : context.surfaceColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: _sortByDistance
                              ? AppColors.primary
                              : context.divColor),
                    ),
                    child: _fetchingLocation
                        ? const SizedBox(
                            width: 60,
                            child: Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded,
                                  size: 14,
                                  color: _sortByDistance
                                      ? AppColors.black
                                      : context.textSecColor),
                              const SizedBox(width: 5),
                              Text(
                                'Near Me',
                                style: TextStyle(
                                  color: _sortByDistance
                                      ? AppColors.black
                                      : context.textSecColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                TealChip(
                  label: 'Airbnb',
                  isSelected: _selectedType == PropertyType.airbnb,
                  onTap: () => setState(() => _selectedType =
                      _selectedType == PropertyType.airbnb
                          ? null
                          : PropertyType.airbnb),
                ),
                const SizedBox(width: 8),
                TealChip(
                  label: 'Apartments',
                  isSelected: _selectedType == PropertyType.apartment,
                  onTap: () => setState(() => _selectedType =
                      _selectedType == PropertyType.apartment
                          ? null
                          : PropertyType.apartment),
                ),
                const SizedBox(width: 8),
                TealChip(
                  label: 'Plots',
                  isSelected: _selectedType == PropertyType.plot,
                  onTap: () => setState(() => _selectedType =
                      _selectedType == PropertyType.plot
                          ? null
                          : PropertyType.plot),
                ),
                const SizedBox(width: 8),
                TealChip(
                  label: 'Houses',
                  isSelected: _selectedType == PropertyType.house,
                  onTap: () => setState(() => _selectedType =
                      _selectedType == PropertyType.house
                          ? null
                          : PropertyType.house),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Location area filter ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LocationAutocompleteField(
              controller: _locationCtrl,
              onLocationSelected: _onAreaLocationSelected,
            ),
          ),

          // ── Radius chips (shown when Near Me or area is active) ────────
          if (_hasActiveCenter) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Radius:',
                      style: TextStyle(
                          color: context.textSecColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ...[5.0, 10.0, 25.0, 50.0].map((km) {
                    final label =
                        km < 10 ? '${km.toInt()} km' : '${km.round()} km';
                    final isSelected = _filterByRadius && _radiusKm == km;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (_filterByRadius && _radiusKm == km) {
                            _filterByRadius = false;
                          } else {
                            _filterByRadius = true;
                            _radiusKm = km;
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.divColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.textSecColor,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ── Price range ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price Range (KES)',
                    style: TextStyle(
                        color: context.textSecColor, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                            color: context.textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Min',
                          hintStyle: TextStyle(
                              color: context.textMutedColor, fontSize: 13),
                          prefixText: 'KES ',
                          prefixStyle: TextStyle(
                              color: context.textSecColor, fontSize: 12),
                          filled: true,
                          fillColor: context.surfaceColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('–',
                          style: TextStyle(
                              color: context.textSecColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w300)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                            color: context.textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Max',
                          hintStyle: TextStyle(
                              color: context.textMutedColor, fontSize: 13),
                          prefixText: 'KES ',
                          prefixStyle: TextStyle(
                              color: context.textSecColor, fontSize: 12),
                          filled: true,
                          fillColor: context.surfaceColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Result count + active filter indicator ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style:
                      TextStyle(color: context.textSecColor, fontSize: 13),
                ),
                if (_sortByDistance && _userPosition != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.near_me_rounded,
                      color: AppColors.primary, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    _filterByRadius
                        ? 'Within ${_radiusKm < 10 ? _radiusKm.toInt() : _radiusKm.round()} km of you'
                        : 'Sorted by distance',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ] else if (_areaLat != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 12),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      _filterByRadius
                          ? 'Within ${_radiusKm < 10 ? _radiusKm.toInt() : _radiusKm.round()} km of ${_locationCtrl.text.split(',').first}'
                          : 'Near ${_locationCtrl.text.split(',').first}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Results list ───────────────────────────────────────────────
          Expanded(
            child: propState.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                color: context.textSecColor, size: 60),
                            const SizedBox(height: 12),
                            Text('No properties found',
                                style: TextStyle(
                                    color: context.textSecColor,
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length,
                        itemBuilder: (_, i) => PropertyListCard(
                          property: results[i],
                          distanceLabel: _distanceLabel(results[i]),
                        ).animate().fadeIn(delay: (i * 60).ms),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 1),
    );
  }
}
