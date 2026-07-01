import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:taftaf/core/models/message_model.dart';
class ChatService {
  static const _chatsKey = 'taftaf_chats_v2';
  static const _msgsKey  = 'taftaf_messages_v2';

  // ── Fetch chats for a user ───────────────────────────────────────────────
  Future<List<ChatModel>> fetchChats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
        .where((c) => c.participantIds.contains(userId))
        .toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }

  // ── Fetch messages for a chat, sorted oldest→newest ──────────────────────
  Future<List<MessageModel>> fetchMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_msgsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .where((m) => m.chatId == chatId)
        .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // ── Send a message ───────────────────────────────────────────────────────
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Persist the message
    final rawMsgs = prefs.getString(_msgsKey) ?? '[]';
    final msgList = (jsonDecode(rawMsgs) as List).cast<Map<String, dynamic>>();
    final msg = MessageModel(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
    );
    msgList.add(msg.toJson());
    await prefs.setString(_msgsKey, jsonEncode(msgList));

    // Update chat preview + increment unread count for the other side
    final rawChats = prefs.getString(_chatsKey) ?? '[]';
    final chatList = (jsonDecode(rawChats) as List).cast<Map<String, dynamic>>();
    final idx = chatList.indexWhere((c) => c['id'] == chatId);
    if (idx != -1) {
      chatList[idx]['lastMessage']     = content;
      chatList[idx]['lastMessageTime'] = msg.timestamp.toIso8601String();
      chatList[idx]['unreadCount']     = (chatList[idx]['unreadCount'] as int? ?? 0) + 1;
      await prefs.setString(_chatsKey, jsonEncode(chatList));
    }

    return msg;
  }

  // ── Mark a chat as read (reset unread count) ─────────────────────────────
  Future<void> markChatRead(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final idx = list.indexWhere((c) => c['id'] == chatId);
    if (idx != -1) {
      list[idx]['unreadCount'] = 0;
      await prefs.setString(_chatsKey, jsonEncode(list));
    }
  }

  // ── Find existing chat or create a new one ───────────────────────────────
  Future<ChatModel> findOrCreateChat({
    required String userId,
    required String userName,
    required String ownerId,
    required String ownerName,
    required String propertyId,
    required String propertyTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatsKey) ?? '[]';
    final all = (jsonDecode(raw) as List)
        .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Return existing if found
    try {
      return all.firstWhere(
        (c) =>
            c.participantIds.contains(userId) &&
            c.participantIds.contains(ownerId) &&
            c.propertyId == propertyId,
      );
    } catch (_) {}

    // Create new
    final chat = ChatModel(
      id: const Uuid().v4(),
      participantIds:   [userId, ownerId],
      participantNames: [userName, ownerName],
      propertyId:   propertyId,
      propertyTitle: propertyTitle,
      lastMessage:     '',
      lastMessageTime: DateTime.now(),
    );
    final updated = [...all.map((c) => c.toJson()), chat.toJson()];
    await prefs.setString(_chatsKey, jsonEncode(updated));
    return chat;
  }
}
