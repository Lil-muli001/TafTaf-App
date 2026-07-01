import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/constants/app_strings.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/core/router/app_router.dart';
import 'package:taftaf/shared/widgets/custom_button.dart';
import 'package:taftaf/shared/widgets/loading_widget.dart';
import 'package:taftaf/shared/widgets/location_autocomplete_field.dart';

// Full amenities catalogue
const _allAmenities = [
  'WiFi / Internet',
  'Parking',
  'Swimming Pool',
  'Air Conditioning',
  'Ceiling Fan',
  'TV / Cable / DSTV',
  'Washing Machine',
  'Generator / Power Backup',
  'Security / CCTV',
  'Gym / Fitness Center',
  'Balcony / Terrace',
  'Garden / Outdoor',
  'Fully Furnished',
  'Pet-Friendly',
  'Elevator / Lift',
  'Water Tank / Backup Water',
  'Borehole / Well',
  'Solar Panels',
  'Fireplace',
  'Kitchen / Cooking Area',
  'Hot Water Heater',
  'Private Compound',
  'Servant\'s Quarters',
];

class AddPropertyScreen extends ConsumerStatefulWidget {
  final PropertyModel? editProperty;
  const AddPropertyScreen({super.key, this.editProperty});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _plotSizeCtrl = TextEditingController();

  PropertyType _type = PropertyType.apartment;
  PriceType _priceType = PriceType.monthly;
  int _bedrooms = 1;
  int _bathrooms = 1;
  bool _isLoading = false;
  bool get _isEditing => widget.editProperty != null;

  double? _latitude;
  double? _longitude;

  // Images — mix of existing URL strings and newly picked XFile paths
  List<String> _existingImages = [];
  final List<XFile> _newImages = [];

  final Set<String> _selectedAmenities = {};

  @override
  void initState() {
    super.initState();
    final p = widget.editProperty;
    if (p != null) {
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description;
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _locationCtrl.text = p.location;
      _plotSizeCtrl.text = p.plotSize ?? '';
      _type = p.type;
      _priceType = p.priceType;
      _bedrooms = p.bedrooms;
      _bathrooms = p.bathrooms;
      _existingImages = List<String>.from(p.images);
      _selectedAmenities.addAll(p.amenities);
      _latitude = p.latitude;
      _longitude = p.longitude;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _plotSizeCtrl.dispose();
    super.dispose();
  }

  int get _totalImages => _existingImages.length + _newImages.length;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(maxWidth: 1200, imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      final remaining = 6 - _totalImages;
      _newImages.addAll(picked.take(remaining));
    });
  }

  Future<void> _pickSingleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;
    if (_totalImages >= 6) return;
    setState(() => _newImages.add(picked));
  }

  void _removeExistingImage(int index) => setState(() => _existingImages.removeAt(index));
  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalImages < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 photo'), backgroundColor: AppColors.error),
      );
      return;
    }

    final user = ref.read(authProvider).currentUser;
    if (user == null) return;

    final allImagePaths = [
      ..._existingImages,
      ..._newImages.map((x) => x.path),
    ];

    final amenitiesList = _selectedAmenities.toList();

    final property = PropertyModel(
      id: widget.editProperty?.id ?? '',
      ownerId: user.id,
      ownerName: user.username,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      priceType: _priceType,
      location: _locationCtrl.text.trim(),
      images: allImagePaths,
      bedrooms: _type == PropertyType.plot ? 0 : _bedrooms,
      bathrooms: _type == PropertyType.plot ? 0 : _bathrooms,
      hasWifi: amenitiesList.any((a) => a.contains('WiFi')),
      hasParking: amenitiesList.contains('Parking'),
      hasPool: amenitiesList.contains('Swimming Pool'),
      plotSize: _type == PropertyType.plot ? _plotSizeCtrl.text.trim() : null,
      amenities: amenitiesList,
      rating: widget.editProperty?.rating ?? 0.0,
      reviewCount: widget.editProperty?.reviewCount ?? 0,
      likedBy: widget.editProperty?.likedBy ?? [],
      viewCount: widget.editProperty?.viewCount ?? 0,
      isAvailable: widget.editProperty?.isAvailable ?? true,
      latitude: _latitude,
      longitude: _longitude,
      createdAt: widget.editProperty?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      // Edits are free — save directly
      setState(() => _isLoading = true);
      await ref.read(propertyProvider.notifier).updateProperty(property);
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated!'), backgroundColor: AppColors.success),
      );
      context.go(AppRoutes.ownerHome);
    } else {
      // New listing — collect KES 100 fee before publishing
      if (!mounted) return;
      context.push(AppRoutes.listingPayment, extra: property);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Property' : AppStrings.addProperty),
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image upload ──────────────────────────────────────────
              _Label('Property Photos (min 3 recommended)'),
              const SizedBox(height: 10),
              _buildImageGrid(),
              const SizedBox(height: 20),

              // ── Property Type ─────────────────────────────────────────
              _Label('Property Type'),
              const SizedBox(height: 8),
              _DropdownField<PropertyType>(
                value: _type,
                items: PropertyType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),

              // ── Title ─────────────────────────────────────────────────
              _Label(AppStrings.propertyTitle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: TextStyle(color: context.textColor),
                decoration: const InputDecoration(hintText: 'e.g. Cozy 2BR Apartment'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // ── Description ───────────────────────────────────────────
              _Label(AppStrings.propertyDesc),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: context.textColor),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your property...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: context.inputBgColor,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // ── Price ─────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Price (KES)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: context.textColor),
                          decoration: const InputDecoration(hintText: '12000'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Price Type'),
                        const SizedBox(height: 8),
                        _DropdownField<PriceType>(
                          value: _priceType,
                          items: const [
                            DropdownMenuItem(value: PriceType.monthly, child: Text('Monthly')),
                            DropdownMenuItem(value: PriceType.daily, child: Text('Per Night')),
                            DropdownMenuItem(value: PriceType.fixed, child: Text('Fixed/Sale')),
                          ],
                          onChanged: (v) => setState(() => _priceType = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Location ──────────────────────────────────────────────
              _Label(AppStrings.propertyLocation),
              const SizedBox(height: 8),
              LocationAutocompleteField(
                controller: _locationCtrl,
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    _latitude = lat;
                    _longitude = lng;
                  });
                },
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              // ── Plot Size (conditional) ───────────────────────────────
              if (_type == PropertyType.plot) ...[
                const SizedBox(height: 16),
                _Label('Plot Size'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _plotSizeCtrl,
                  style: TextStyle(color: context.textColor),
                  decoration: const InputDecoration(hintText: 'e.g. 2.5 Acres or 100×250 ft'),
                ),
              ],

              // ── Bedrooms / Bathrooms (not for plots) ──────────────────
              if (_type != PropertyType.plot) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Counter(label: 'Bedrooms', value: _bedrooms, onChanged: (v) => setState(() => _bedrooms = v))),
                    const SizedBox(width: 12),
                    Expanded(child: _Counter(label: 'Bathrooms', value: _bathrooms, onChanged: (v) => setState(() => _bathrooms = v))),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Amenities ─────────────────────────────────────────
                _Label('Amenities'),
                const SizedBox(height: 10),
                _buildAmenitiesGrid(),
              ],

              const SizedBox(height: 32),
              PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Publish Listing',
                isLoading: _isLoading,
                onTap: _submit,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final allPreviews = [
      ..._existingImages.asMap().entries.map((e) => _ImagePreview(
            key: ValueKey('existing_${e.key}'),
            source: e.value,
            isNetwork: e.value.startsWith('http'),
            onRemove: () => _removeExistingImage(e.key),
          )),
      ..._newImages.asMap().entries.map((e) => _ImagePreview(
            key: ValueKey('new_${e.key}'),
            source: e.value.path,
            isNetwork: false,
            onRemove: () => _removeNewImage(e.key),
          )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allPreviews.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...allPreviews,
                if (_totalImages < 6)
                  GestureDetector(
                    onTap: _pickSingleImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: context.inputBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                          SizedBox(height: 4),
                          Text('Add Photo', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: context.inputBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 40),
                  const SizedBox(height: 8),
                  const Text('Tap to add photos', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Add at least 3 · max 6', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
                ],
              ),
            ),
          ),
        if (_totalImages > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('$_totalImages / 6 photos added', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allAmenities.map((amenity) {
        final selected = _selectedAmenities.contains(amenity);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedAmenities.remove(amenity);
            } else {
              _selectedAmenities.add(amenity);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? AppColors.primary : context.divColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_circle_rounded, color: AppColors.white, size: 14),
                  const SizedBox(width: 4),
                ],
                Text(
                  amenity,
                  style: TextStyle(
                    color: selected ? AppColors.white : context.textSecColor,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _typeLabel(PropertyType t) {
    switch (t) {
      case PropertyType.airbnb: return 'Airbnb / Short Stay';
      case PropertyType.apartment: return 'Apartment';
      case PropertyType.house: return 'House';
      case PropertyType.plot: return 'Plot / Land';
      case PropertyType.commercial: return 'Commercial';
    }
  }
}

class _ImagePreview extends StatelessWidget {
  final String source;
  final bool isNetwork;
  final VoidCallback onRemove;

  const _ImagePreview({super.key, required this.source, required this.isNetwork, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PropertyImageWidget(path: source, width: 100, height: 100),
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: AppColors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.inputBgColor, borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: context.surfaceColor,
          style: TextStyle(color: context.textColor, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, color: context.textSecColor),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: context.textSecColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _Counter({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.divColor)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: context.textSecColor, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () { if (value > 0) onChanged(value - 1); },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: context.inputBgColor, shape: BoxShape.circle),
                  child: Icon(Icons.remove, size: 16, color: context.textColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$value', style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 16, color: AppColors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
