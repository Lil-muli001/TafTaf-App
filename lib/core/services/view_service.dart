import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of property IDs a client has already paid to view.
class ViewService {
  static const _prefix = 'client_viewed_';

  Future<bool> hasViewed(String userId, String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    if (raw == null) return false;
    return (jsonDecode(raw) as List).contains(propertyId);
  }

  Future<void> markAsViewed(String userId, String propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$userId');
    final list = raw != null ? List<String>.from(jsonDecode(raw) as List) : <String>[];
    if (!list.contains(propertyId)) {
      list.add(propertyId);
      await prefs.setString('$_prefix$userId', jsonEncode(list));
    }
  }
}
