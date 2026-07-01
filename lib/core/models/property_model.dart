enum PropertyType { airbnb, apartment, house, plot, commercial }

enum PriceType { daily, monthly, fixed }

class PropertyModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final PropertyType type;
  final double price;
  final PriceType priceType;
  final String location;
  final List<String> images;
  final int bedrooms;
  final int bathrooms;
  final bool hasWifi;
  final bool hasParking;
  final bool hasPool;
  final String? plotSize;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final List<String> likedBy;
  final bool isAvailable;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final int viewCount;
  final DateTime createdAt;

  const PropertyModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.priceType,
    required this.location,
    required this.images,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.hasWifi = false,
    this.hasParking = false,
    this.hasPool = false,
    this.plotSize,
    this.amenities = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.likedBy = const [],
    this.isAvailable = true,
    this.isVerified = false,
    this.latitude,
    this.longitude,
    this.viewCount = 0,
    required this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String get typeLabel {
    switch (type) {
      case PropertyType.airbnb: return 'Airbnb';
      case PropertyType.apartment: return 'Apartment';
      case PropertyType.house: return 'House';
      case PropertyType.plot: return 'Plot/Land';
      case PropertyType.commercial: return 'Commercial';
    }
  }

  String get priceSuffix {
    switch (priceType) {
      case PriceType.daily: return '/night';
      case PriceType.monthly: return '/month';
      case PriceType.fixed: return '';
    }
  }

  String get priceFormatted {
    if (price >= 1000000) {
      return 'KES ${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      final k = price / 1000;
      final s = k == k.truncateToDouble() ? k.toInt().toString() : k.toStringAsFixed(1);
      return 'KES ${s}K';
    }
    return 'KES ${price.toStringAsFixed(0)}';
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String,
      type: PropertyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PropertyType.apartment,
      ),
      price: (json['price'] as num).toDouble(),
      priceType: PriceType.values.firstWhere(
        (e) => e.name == json['priceType'],
        orElse: () => PriceType.monthly,
      ),
      location: json['location'] as String,
      images: List<String>.from(json['images'] as List? ?? []),
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      hasWifi: json['hasWifi'] as bool? ?? false,
      hasParking: json['hasParking'] as bool? ?? false,
      hasPool: json['hasPool'] as bool? ?? false,
      plotSize: json['plotSize'] as String?,
      amenities: List<String>.from(json['amenities'] as List? ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      likedBy: List<String>.from(json['likedBy'] as List? ?? []),
      isAvailable: json['isAvailable'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      viewCount: json['viewCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'title': title,
        'description': description,
        'type': type.name,
        'price': price,
        'priceType': priceType.name,
        'location': location,
        'images': images,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'hasWifi': hasWifi,
        'hasParking': hasParking,
        'hasPool': hasPool,
        'plotSize': plotSize,
        'amenities': amenities,
        'rating': rating,
        'reviewCount': reviewCount,
        'likedBy': likedBy,
        'isAvailable': isAvailable,
        'isVerified': isVerified,
        'latitude': latitude,
        'longitude': longitude,
        'viewCount': viewCount,
        'createdAt': createdAt.toIso8601String(),
      };

  PropertyModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? title,
    String? description,
    PropertyType? type,
    double? price,
    PriceType? priceType,
    String? location,
    List<String>? images,
    int? bedrooms,
    int? bathrooms,
    bool? hasWifi,
    bool? hasParking,
    bool? hasPool,
    String? plotSize,
    List<String>? amenities,
    double? rating,
    int? reviewCount,
    List<String>? likedBy,
    bool? isAvailable,
    bool? isVerified,
    double? latitude,
    double? longitude,
    int? viewCount,
    DateTime? createdAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      location: location ?? this.location,
      images: images ?? this.images,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      hasWifi: hasWifi ?? this.hasWifi,
      hasParking: hasParking ?? this.hasParking,
      hasPool: hasPool ?? this.hasPool,
      plotSize: plotSize ?? this.plotSize,
      amenities: amenities ?? this.amenities,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      likedBy: likedBy ?? this.likedBy,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
