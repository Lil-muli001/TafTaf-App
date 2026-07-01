import 'package:taftaf/core/models/property_model.dart';

enum AdPackage { weekly, monthly }

class AdModel {
  final String id;
  final String propertyId;
  final String ownerId;
  final AdPackage package;
  final int amountPaid;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int impressions;

  const AdModel({
    required this.id,
    required this.propertyId,
    required this.ownerId,
    required this.package,
    required this.amountPaid,
    required this.createdAt,
    required this.expiresAt,
    this.impressions = 0,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  Duration get remaining => expiresAt.difference(DateTime.now());

  String get packageLabel => AdModel.packageName(package);

  static String packageName(AdPackage p) {
    switch (p) {
      case AdPackage.weekly: return '1 Week';
      case AdPackage.monthly: return '1 Month';
    }
  }

  static int packagePrice(AdPackage p) {
    switch (p) {
      case AdPackage.weekly: return 50;
      case AdPackage.monthly: return 150;
    }
  }

  static Duration packageDuration(AdPackage p) {
    switch (p) {
      case AdPackage.weekly: return const Duration(days: 7);
      case AdPackage.monthly: return const Duration(days: 30);
    }
  }

  static String packageDurationLabel(AdPackage p) {
    switch (p) {
      case AdPackage.weekly: return '1 week';
      case AdPackage.monthly: return '1 month';
    }
  }

  static String packageReachLabel(AdPackage p) {
    switch (p) {
      case AdPackage.weekly: return '7 days of exposure across the feed';
      case AdPackage.monthly: return '30 days of maximum reach';
    }
  }

  static String formatRemaining(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return 'Expired';
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      ownerId: json['ownerId'] as String,
      package: AdPackage.values.firstWhere(
        (e) => e.name == json['package'],
        orElse: () => AdPackage.weekly,
      ),
      amountPaid: json['amountPaid'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      impressions: json['impressions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'propertyId': propertyId,
    'ownerId': ownerId,
    'package': package.name,
    'amountPaid': amountPaid,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'impressions': impressions,
  };

  AdModel copyWith({int? impressions}) => AdModel(
    id: id,
    propertyId: propertyId,
    ownerId: ownerId,
    package: package,
    amountPaid: amountPaid,
    createdAt: createdAt,
    expiresAt: expiresAt,
    impressions: impressions ?? this.impressions,
  );
}

class AdWithProperty {
  final AdModel ad;
  final PropertyModel property;
  const AdWithProperty({required this.ad, required this.property});
}
