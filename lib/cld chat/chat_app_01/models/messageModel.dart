import 'package:uuid/uuid.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String chatId;
  final String content;
  final DateTime createdAt;
  bool isSynced; // For offline support

  MessageModel({
    required this.id,
    required this.senderId,
    required this.chatId,
    required this.content,

    required this.createdAt,
    this.isSynced = false,
  });

  /// For creating a new outgoing message
  factory MessageModel.create({
    required String chatId,
    required String senderId,
    required String text,
  }) {
    return MessageModel(
      id: const Uuid().v4(),
      senderId: senderId,
      chatId: chatId,
      content: text,

      createdAt: DateTime.now(),
      isSynced: false,
    );
  }

  /// Convert to Map (for both Supabase and local Hive)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'chat_id': chatId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      // 'is_synced': isSynced,
    };
  }

  /// From Map (works for both Supabase & Hive)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? const Uuid().v4()).toString(),
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      chatId: json['chat_id'] ?? json['chatId'] ?? '',
      content: json['content'] ?? '',
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      isSynced: json['is_synced'] ?? json['isSynced'] ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}
