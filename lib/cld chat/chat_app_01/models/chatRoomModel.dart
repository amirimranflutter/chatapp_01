import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';

class ChatRoomModel {
  final String id;
  final List<String> participantIds; // User IDs
  final String? name;
  final String type; // "private" or "group"
  final DateTime createdAt;
  final MessageModel? lastMessage; // optional: latest message info

  ChatRoomModel({
    required this.id,
    required this.participantIds,
    this.name,
    required this.type,
    required this.createdAt,
    this.lastMessage,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    // Parse last message if it exists
    final lastMsgList = map['last_message'] as List?;

    return ChatRoomModel(
      id: map['id'] ?? '',
      participantIds: (map['participants'] as List?)
          ?.map((p) => p['user_id'] as String)
          .toList() ??
          [],
      name: map['name'],
      type: map['type'] ?? 'private',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      lastMessage: lastMsgList != null && lastMsgList.isNotEmpty
          ? MessageModel.fromJson(lastMsgList.first)
          : null,
    );
  }
  String otherParticipantName(String currentUserId) {
    // Find the first participant that is NOT the current user
    final otherId = participantIds.firstWhere(
          (id) => id != currentUserId,
      orElse: () => 'Unknown',
    );
    return otherId; // or fetch actual name if available in your profile map
  }
}


