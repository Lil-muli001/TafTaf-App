class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String calleeId;
  final String calleeName;
  final String channelId;
  final DateTime initiatedAt;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    required this.calleeName,
    required this.channelId,
    required this.initiatedAt,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) => CallModel(
        id: json['id'] as String,
        callerId: json['callerId'] as String,
        callerName: json['callerName'] as String,
        calleeId: json['calleeId'] as String,
        calleeName: json['calleeName'] as String,
        channelId: json['channelId'] as String,
        initiatedAt: DateTime.parse(json['initiatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'callerId': callerId,
        'callerName': callerName,
        'calleeId': calleeId,
        'calleeName': calleeName,
        'channelId': channelId,
        'initiatedAt': initiatedAt.toIso8601String(),
      };

  /// Derives a stable, symmetric Agora channel name from any two user IDs.
  /// Sorting ensures caller and callee always resolve to the same channel.
  static String deriveChannel(String userId1, String userId2) {
    final a = userId1.replaceAll('-', '');
    final b = userId2.replaceAll('-', '');
    final sorted = [a, b]..sort();
    // 15 chars each → "tc_{15}_{15}" = 34 chars total (Agora limit: 64)
    return 'tc_${sorted[0].substring(0, 15)}_${sorted[1].substring(0, 15)}';
  }
}
