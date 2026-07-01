import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:uuid/uuid.dart';

class BookingService {
  static const _key = 'bookings_v2';

  Future<List<BookingModel>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == null) return [];
    try {
      final list = jsonDecode(stored) as List;
      return list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<BookingModel> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(bookings.map((b) => b.toJson()).toList()),
    );
  }

  Future<List<BookingModel>> fetchByOwner(String ownerId) async {
    final all = await _loadAll();
    return all
        .where((b) => b.ownerId == ownerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<BookingModel>> fetchByClient(String clientId) async {
    final all = await _loadAll();
    return all
        .where((b) => b.clientId == clientId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<BookingModel> createBooking({
    required String propertyId,
    required String propertyTitle,
    required String ownerId,
    required String clientId,
    required String clientName,
    required BookingType type,
    required DateTime scheduledDate,
    String? message,
    DateTime? checkIn,
    DateTime? checkOut,
    double? pricePerNight,
    required String propertyTypeName,
    int? contractMonths,
  }) async {
    final all = await _loadAll();
    final booking = BookingModel.fromJson({
      'id': const Uuid().v4(),
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'ownerId': ownerId,
      'clientId': clientId,
      'clientName': clientName,
      'status': BookingStatus.pending.name,
      'type': type.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
      'checkIn': checkIn?.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'pricePerNight': pricePerNight,
      'rejectionReason': null,
      'propertyType': propertyTypeName,
      'contractMonths': contractMonths,
    });
    all.insert(0, booking);
    await _saveAll(all);
    return booking;
  }

  Future<BookingModel> updateStatus(
    String id,
    BookingStatus status, {
    String? rejectionReason,
  }) async {
    final all = await _loadAll();
    final idx = all.indexWhere((b) => b.id == id);
    if (idx == -1) throw Exception('Booking not found');
    final updated = all[idx].copyWith(
      status: status,
      rejectionReason: rejectionReason,
    );
    all[idx] = updated;
    await _saveAll(all);
    return updated;
  }
}
