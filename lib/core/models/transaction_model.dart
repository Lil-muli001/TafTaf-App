enum TransactionType { registrationFee, propertyPurchase, propertyRent }

enum TransactionStatus { pending, completed, failed }

class TransactionModel {
  final String id;
  final String userId;
  final String? propertyId;
  final TransactionType type;
  final double amount;
  final TransactionStatus status;
  final String? mpesaRef;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    this.propertyId,
    required this.type,
    required this.amount,
    required this.status,
    this.mpesaRef,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      propertyId: json['propertyId'] as String?,
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      amount: (json['amount'] as num).toDouble(),
      status: TransactionStatus.values.firstWhere((e) => e.name == json['status']),
      mpesaRef: json['mpesaRef'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'propertyId': propertyId,
        'type': type.name,
        'amount': amount,
        'status': status.name,
        'mpesaRef': mpesaRef,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum NotificationType {
  welcome,
  accountInfo,
  bookingReceived,
  bookingConfirmed,
  bookingCancelled,
  newMessage,
  paymentSuccess,
  propertyVerified,
  system,
  missedCall,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? propertyId;
  final bool isRead;
  final DateTime createdAt;
  final NotificationType type;
  final String? callerId;
  final String? callerName;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.propertyId,
    this.isRead = false,
    required this.createdAt,
    this.type = NotificationType.system,
    this.callerId,
    this.callerName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      propertyId: json['propertyId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      callerId: json['callerId'] as String?,
      callerName: json['callerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'propertyId': propertyId,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
        'callerId': callerId,
        'callerName': callerName,
      };

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      propertyId: propertyId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      type: type,
      callerId: callerId,
      callerName: callerName,
    );
  }
}
