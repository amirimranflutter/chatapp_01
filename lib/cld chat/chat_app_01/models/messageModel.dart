// models/message_model.dart

import 'package:uuid/uuid.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  bool isSynced; // For offline support

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.isSynced = false,
  });

  /// For creating a new outgoing message
  factory MessageModel.create({
    required String senderId,
    required String receiverId,
    required String text,
  }) {
    return MessageModel(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
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
      'receiver_id': receiverId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// From Supabase (Map)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      isSynced: true,
    );
  }
}
