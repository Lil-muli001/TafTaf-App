import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:taftaf/core/constants/api_keys.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String formattedAddress;

  const PlaceDetails({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class LocationService {
  // ── Current position ─────────────────────────────────────────────────────

  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Timeout guards against emulator/headless devices where the system
        // permission dialog never resolves.
        permission = await Geolocator.requestPermission()
            .timeout(
              const Duration(seconds: 12),
              onTimeout: () => LocationPermission.denied,
            );
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Places Autocomplete ──────────────────────────────────────────────────

  Future<List<PlacePrediction>> getAutocompleteSuggestions(String input) async {
    if (!ApiKeys.isConfigured || input.trim().isEmpty) return [];

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input.trim(),
      'key': ApiKeys.googleMaps,
      'components': 'country:ke',
      'language': 'en',
      'types': 'geocode',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK' && status != 'ZERO_RESULTS') return [];
      if (status == 'ZERO_RESULTS') return [];

      return (data['predictions'] as List<dynamic>).map((p) {
        final sf = (p['structured_formatting'] as Map<String, dynamic>?) ?? {};
        return PlacePrediction(
          placeId: p['place_id'] as String,
          description: p['description'] as String,
          mainText: sf['main_text'] as String? ?? p['description'] as String,
          secondaryText: sf['secondary_text'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Place Details (lat/lng from place_id) ────────────────────────────────

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!ApiKeys.isConfigured) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'key': ApiKeys.googleMaps,
      'fields': 'geometry,formatted_address',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final result = data['result'] as Map<String, dynamic>;
      final loc = (result['geometry'] as Map)['location'] as Map<String, dynamic>;

      return PlaceDetails(
        lat: (loc['lat'] as num).toDouble(),
        lng: (loc['lng'] as num).toDouble(),
        formattedAddress: result['formatted_address'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  // ── Distance helpers ─────────────────────────────────────────────────────

  /// Returns distance in kilometres between two coordinates (Haversine).
  double distanceBetweenKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  /// Human-readable distance string.
  String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}
