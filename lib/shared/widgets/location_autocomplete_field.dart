import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/constants/api_keys.dart';
import 'package:taftaf/core/services/location_service.dart';

/// A text field that queries Google Places Autocomplete as the user types,
/// shows a floating suggestion overlay (above keyboard), and resolves the
/// selected place to lat/lng via Place Details.
class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String address, double lat, double lng) onLocationSelected;
  final String? Function(String?)? validator;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
    this.validator,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState
    extends State<LocationAutocompleteField> {
  final _svc        = LocationService();
  final _focusNode  = FocusNode();
  final _layerLink  = LayerLink();
  OverlayEntry?     _overlayEntry;

  List<PlacePrediction> _suggestions = [];
  bool _isFetching           = false;
  bool _suppressNextChange   = false;
  Timer? _debounce;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  // ── Focus ────────────────────────────────────────────────────────────────────

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Small delay so a tap on a suggestion registers before the overlay closes.
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _removeOverlay();
      });
    }
  }

  // ── Overlay management ───────────────────────────────────────────────────────

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty || !mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    final fieldWidth = (box != null && box.hasSize && box.size.width > 0)
        ? box.size.width
        : screenWidth - 32;

    _overlayEntry = OverlayEntry(
      builder: (_) => _SuggestionsOverlay(
        link:        _layerLink,
        width:       fieldWidth,
        suggestions: _suggestions,
        onSelect:    _selectPrediction,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  // ── Text changes ─────────────────────────────────────────────────────────────

  void _onTextChanged() {
    if (_suppressNextChange) {
      _suppressNextChange = false;
      return;
    }
    _debounce?.cancel();
    final q = widget.controller.text.trim();
    if (q.isEmpty) {
      _removeOverlay();
      if (mounted) setState(() { _isFetching = false; _suggestions = []; });
      return;
    }
    if (mounted) setState(() => _isFetching = true);
    _debounce = Timer(const Duration(milliseconds: 420), () => _fetch(q));
  }

  Future<void> _fetch(String query) async {
    final results = await _svc.getAutocompleteSuggestions(query);
    if (!mounted) return;
    setState(() { _suggestions = results; _isFetching = false; });
    _showOverlay();
  }

  // ── Selection ────────────────────────────────────────────────────────────────

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    _suppressNextChange = true;
    widget.controller.text = prediction.description;
    widget.controller.selection =
        TextSelection.collapsed(offset: prediction.description.length);
    _suggestions = [];
    _removeOverlay();
    if (mounted) setState(() => _isFetching = true);
    _focusNode.unfocus();

    final details = await _svc.getPlaceDetails(prediction.placeId);
    if (!mounted) return;
    setState(() => _isFetching = false);
    if (details != null) {
      widget.onLocationSelected(
          prediction.description, details.lat, details.lng);
    }
  }

  void _clear() {
    widget.controller.clear();
    _suggestions = [];
    _removeOverlay();
    if (mounted) setState(() => _isFetching = false);
    _focusNode.requestFocus();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller:      widget.controller,
        focusNode:       _focusNode,
        style:           TextStyle(color: context.textColor, fontSize: 14),
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (_) {
          if (_suggestions.isNotEmpty) _selectPrediction(_suggestions.first);
        },
        decoration: InputDecoration(
          hintText: ApiKeys.isConfigured
              ? 'Search location, e.g. Westlands, Nairobi'
              : 'Type location (configure API key for autocomplete)',
          hintStyle: TextStyle(color: context.textMutedColor, fontSize: 13),
          prefixIcon: const Icon(
              Icons.location_on_outlined, color: AppColors.primary, size: 20),
          suffixIcon: _isFetching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: context.textSecColor, size: 18),
                      onPressed: _clear,
                    )
                  : null,
          filled:      true,
          fillColor:   context.inputBgColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: widget.validator,
      ),
    );
  }
}

// ── Floating suggestions overlay ──────────────────────────────────────────────

class _SuggestionsOverlay extends StatelessWidget {
  final LayerLink link;
  final double width;
  final List<PlacePrediction> suggestions;
  final Future<void> Function(PlacePrediction) onSelect;

  const _SuggestionsOverlay({
    required this.link,
    required this.width,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link:              link,
        showWhenUnlinked:  false,
        targetAnchor:      Alignment.bottomLeft,
        followerAnchor:    Alignment.topLeft,
        offset:            const Offset(0, 4),
        child: Material(
          color:       Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.divColor),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset:     const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                shrinkWrap: true,
                padding:    EdgeInsets.zero,
                itemCount:  suggestions.length.clamp(0, 5),
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: context.divColor, indent: 58),
                itemBuilder: (_, i) {
                  final s = suggestions[i];
                  return InkWell(
                    onTap: () => onSelect(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width:  32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.mainText,
                                  style: TextStyle(
                                    color:      context.textColor,
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines:  1,
                                  overflow:  TextOverflow.ellipsis,
                                ),
                                if (s.secondaryText.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    s.secondaryText,
                                    style: TextStyle(
                                        color:    context.textSecColor,
                                        fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.north_west_rounded,
                              color: context.textMutedColor, size: 14),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
