// models/message_model.dart

import 'package:uuid/uuid.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String chatId;
  final String text;
  final DateTime createdAt;
  bool isSynced; // For offline support

  MessageModel({
    required this.id,
    required this.senderId,
    required this.chatId,
    required this.text,
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
      text: text,
      createdAt: DateTime.now(),
      isSynced: false,
    );
  }

  /// Convert for Supabase (Map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'chat_id': chatId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// From Supabase (Map)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      chatId: json['chat_id'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      isSynced: true,
    );
  }
}
