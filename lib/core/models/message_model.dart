class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  MessageModel copyWith({bool? isRead}) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class ChatModel {
  final String id;
  final List<String> participantIds;
  final List<String> participantNames;
  final String propertyId;
  final String propertyTitle;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.propertyId,
    required this.propertyTitle,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      participantNames: List<String>.from(json['participantNames'] as List),
      propertyId: json['propertyId'] as String,
      propertyTitle: json['propertyTitle'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'propertyId': propertyId,
        'propertyTitle': propertyTitle,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'unreadCount': unreadCount,
      };
}
