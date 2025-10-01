
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/userModel.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final UserModel? sender;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      content: map['content'],
      messageType: map['message_type'] ?? 'text',
      createdAt: DateTime.parse(map['created_at']),
      sender: map['profiles'] != null ? UserModel.fromMap(map['profiles']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
