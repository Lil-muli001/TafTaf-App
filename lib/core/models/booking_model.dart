import 'package:taftaf/core/models/property_model.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }
enum BookingType { viewing, inquiry, rental }

class BookingModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String clientId;
  final String clientName;
  final BookingStatus status;
  final BookingType type;
  final DateTime scheduledDate;
  final String? message;
  final DateTime createdAt;
  // Airbnb-specific
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double? pricePerNight;
  // Owner response
  final String? rejectionReason;
  // Property context
  final PropertyType propertyType;
  // Rental-specific
  final int? contractMonths;

  const BookingModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerId,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.type,
    required this.scheduledDate,
    this.message,
    required this.createdAt,
    this.checkIn,
    this.checkOut,
    this.pricePerNight,
    this.rejectionReason,
    this.propertyType = PropertyType.apartment,
    this.contractMonths,
  });

  int get totalNights {
    if (checkIn == null || checkOut == null) return 0;
    return checkOut!.difference(checkIn!).inDays;
  }

  double get totalAmount {
    if (pricePerNight != null && totalNights > 0) return pricePerNight! * totalNights;
    return 0;
  }

  bool get isAirbnb => propertyType == PropertyType.airbnb;

  String get statusLabel => switch (status) {
    BookingStatus.pending   => 'Pending',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.completed => 'Completed',
  };

  String get typeLabel => switch (type) {
    BookingType.viewing => 'Viewing',
    BookingType.inquiry => 'Inquiry',
    BookingType.rental  => 'Rent',
  };

  BookingModel copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? ownerId,
    String? clientId,
    String? clientName,
    BookingStatus? status,
    BookingType? type,
    DateTime? scheduledDate,
    String? message,
    DateTime? createdAt,
    DateTime? checkIn,
    DateTime? checkOut,
    double? pricePerNight,
    String? rejectionReason,
    PropertyType? propertyType,
    int? contractMonths,
  }) {
    return BookingModel(
      id:            id            ?? this.id,
      propertyId:    propertyId    ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      ownerId:       ownerId       ?? this.ownerId,
      clientId:      clientId      ?? this.clientId,
      clientName:    clientName    ?? this.clientName,
      status:        status        ?? this.status,
      type:          type          ?? this.type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      message:       message       ?? this.message,
      createdAt:     createdAt     ?? this.createdAt,
      checkIn:       checkIn       ?? this.checkIn,
      checkOut:      checkOut      ?? this.checkOut,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      propertyType:  propertyType  ?? this.propertyType,
      contractMonths: contractMonths ?? this.contractMonths,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'propertyId':     propertyId,
    'propertyTitle':  propertyTitle,
    'ownerId':        ownerId,
    'clientId':       clientId,
    'clientName':     clientName,
    'status':         status.name,
    'type':           type.name,
    'scheduledDate':  scheduledDate.toIso8601String(),
    'message':        message,
    'createdAt':      createdAt.toIso8601String(),
    'checkIn':        checkIn?.toIso8601String(),
    'checkOut':       checkOut?.toIso8601String(),
    'pricePerNight':  pricePerNight,
    'rejectionReason': rejectionReason,
    'propertyType':   propertyType.name,
    'contractMonths': contractMonths,
  };

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id:            json['id'] as String,
      propertyId:    json['propertyId'] as String,
      propertyTitle: json['propertyTitle'] as String,
      ownerId:       json['ownerId'] as String,
      clientId:      json['clientId'] as String,
      clientName:    json['clientName'] as String,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      type: BookingType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BookingType.inquiry,
      ),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      message:       json['message'] as String?,
      createdAt:     DateTime.parse(json['createdAt'] as String),
      checkIn:       json['checkIn'] != null ? DateTime.parse(json['checkIn'] as String) : null,
      checkOut:      json['checkOut'] != null ? DateTime.parse(json['checkOut'] as String) : null,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      rejectionReason: json['rejectionReason'] as String?,
      contractMonths: json['contractMonths'] as int?,
      propertyType: PropertyType.values.firstWhere(
        (e) => e.name == (json['propertyType'] ?? 'apartment'),
        orElse: () => PropertyType.apartment,
      ),
    );
  }
}
