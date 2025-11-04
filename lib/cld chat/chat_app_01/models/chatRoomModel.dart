import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';

import '../services/contactService/hive_db_service.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participantIds.map((id) => {'user_id': id}).toList(),
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'last_message': lastMessage?.toJson(),
    };
  }

  /// Return the other participant's ID (for private chats)
  String otherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
          (id) => id != currentUserId,
      orElse: () => 'Unknown',
    );
  }

  Future<String> otherParticipantName(String currentUserId) async {
    final otherId = participantIds.firstWhere(
          (id) => id != currentUserId,
      orElse: () => 'Unknown',
    );

    if (otherId == 'Unknown') return 'Unknown';

    // Try fetching contact info from Hive
    final hiveDB = HiveDBService();
    final contact = await hiveDB.getContactByContactId(otherId);

    // If found in local contacts, return their name, otherwise show fallback
    return contact?.name ?? 'Unknown User';
  }
}

