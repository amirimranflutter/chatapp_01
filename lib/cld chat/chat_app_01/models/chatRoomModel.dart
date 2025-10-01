import 'package:chat_app_cld/cld chat/chat_app_01/models/userModel.dart';

class ChatRoomModel {
  final String id;
  final String? name;
  final String type;
  final String createdBy; // keep this if still needed
  final String? creatorProfileId; // ✅ NEW FIELD
  final DateTime createdAt;
  final UserModel? creator;
  final List<UserModel> participants;

  ChatRoomModel({
    required this.id,
    this.name,
    required this.type,
    required this.createdBy,
    this.creatorProfileId, // ✅ added here
    required this.createdAt,
    this.creator,
    this.participants = const [],
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      createdBy: map['created_by'], // still reading old field
      creatorProfileId: map['creator_profile_id'], // ✅ new field
      createdAt: DateTime.parse(map['created_at']),
      creator: map['profiles'] != null
          ? UserModel.fromMap(map['profiles'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created_by': createdBy, // optional to keep
      'creator_profile_id': creatorProfileId, // ✅ new field
      'created_at': createdAt.toIso8601String(),
    };
  }
}
