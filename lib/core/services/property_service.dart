import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:taftaf/core/models/ad_model.dart';
import 'package:taftaf/core/models/property_model.dart';

class PropertyService {
  static const _propertiesKey = 'taftaf_properties';

  List<PropertyModel> _cache = [];

  Future<List<PropertyModel>> fetchProperties({
    PropertyType? type,
    String? ownerId,
    String? query,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_propertiesKey);

    List<PropertyModel> all = [];

    if (stored != null) {
      all = (jsonDecode(stored) as List)
          .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (type != null) all = all.where((p) => p.type == type).toList();
    if (ownerId != null) all = all.where((p) => p.ownerId == ownerId).toList();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      all = all
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }

    _cache = all;
    return all;
  }

  Future<PropertyModel?> fetchById(String id) async {
    final all = await fetchProperties();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<PropertyModel> addProperty(PropertyModel property) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_propertiesKey);
    List<Map<String, dynamic>> list = [];
    if (stored != null) {
      list = (jsonDecode(stored) as List).cast<Map<String, dynamic>>();
    }

    final newProp = property.copyWith(id: const Uuid().v4());
    list.add(newProp.toJson());
    await prefs.setString(_propertiesKey, jsonEncode(list));
    return newProp;
  }

  Future<PropertyModel> updateProperty(PropertyModel property) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_propertiesKey);
    List<Map<String, dynamic>> list = [];
    if (stored != null) {
      list = (jsonDecode(stored) as List).cast<Map<String, dynamic>>();
    }

    final idx = list.indexWhere((p) => p['id'] == property.id);
    if (idx != -1) {
      list[idx] = property.toJson();
    } else {
      list.add(property.toJson());
    }

    await prefs.setString(_propertiesKey, jsonEncode(list));
    return property;
  }

  Future<void> deleteProperty(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_propertiesKey);
    if (stored == null) return;

    final list = (jsonDecode(stored) as List).cast<Map<String, dynamic>>();
    list.removeWhere((p) => p['id'] == id);
    await prefs.setString(_propertiesKey, jsonEncode(list));
  }

  Future<PropertyModel> toggleLike(String propertyId, String userId) async {
    final all = await fetchProperties();
    final prop = all.firstWhere((p) => p.id == propertyId);

    final liked = List<String>.from(prop.likedBy);
    if (liked.contains(userId)) {
      liked.remove(userId);
    } else {
      liked.add(userId);
    }

    final updated = prop.copyWith(likedBy: liked);
    await updateProperty(updated);
    return updated;
  }

  Future<void> incrementView(String propertyId) async {
    final all = await fetchProperties();
    try {
      final prop = all.firstWhere((p) => p.id == propertyId);
      final updated = prop.copyWith(viewCount: prop.viewCount + 1);
      await updateProperty(updated);
    } catch (_) {}
  }

  Future<List<PropertyModel>> fetchFavorites(String userId) async {
    final all = await fetchProperties();
    return all.where((p) => p.likedBy.contains(userId)).toList();
  }

  static const _adsKey = 'taftaf_ads';

  Future<List<AdModel>> fetchActiveAds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_adsKey);
    List<AdModel> all = [];
    if (stored != null) {
      final extra = (jsonDecode(stored) as List)
          .map((e) => AdModel.fromJson(e as Map<String, dynamic>))
          .toList();
      all = [...all, ...extra];
    }

    return all.where((a) => a.isActive).toList();
  }

  Future<AdModel> boostProperty({
    required String propertyId,
    required String ownerId,
    required AdPackage package,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_adsKey);
    List<Map<String, dynamic>> list = [];
    if (stored != null) {
      list = (jsonDecode(stored) as List).cast<Map<String, dynamic>>();
    }
    final now = DateTime.now();
    final ad = AdModel(
      id: const Uuid().v4(),
      propertyId: propertyId,
      ownerId: ownerId,
      package: package,
      amountPaid: AdModel.packagePrice(package),
      createdAt: now,
      expiresAt: now.add(AdModel.packageDuration(package)),
    );
    list.add(ad.toJson());
    await prefs.setString(_adsKey, jsonEncode(list));
    return ad;
  }

  Future<List<AdWithProperty>> fetchAdsWithProperties() async {
    final ads = await fetchActiveAds();
    // Reuse in-memory cache when available — avoids a redundant SharedPrefs read
    final props = _cache.isNotEmpty ? _cache : await fetchProperties();
    final result = <AdWithProperty>[];
    for (final ad in ads) {
      final matches = props.where((p) => p.id == ad.propertyId);
      if (matches.isNotEmpty) result.add(AdWithProperty(ad: ad, property: matches.first));
    }
    return result;
  }

  Map<String, dynamic> getAnalytics(String ownerId) {
    final owned = _cache.where((p) => p.ownerId == ownerId).toList();
    final totalViews = owned.fold(0, (sum, p) => sum + p.viewCount);
    final totalLikes = owned.fold(0, (sum, p) => sum + p.likedBy.length);
    final avgRating = owned.isEmpty
        ? 0.0
        : owned.fold(0.0, (sum, p) => sum + p.rating) / owned.length;

    return {
      'totalProperties': owned.length,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'avgRating': avgRating,
      'properties': owned,
    };
  }
}
