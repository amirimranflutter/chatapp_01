class ChatRoom {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;

  ChatRoom({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageContent,
    this.lastMessageAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'participant1_id': participant1Id,
    'participant2_id': participant2Id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'last_message_content': lastMessageContent,
    'last_message_at': lastMessageAt?.toIso8601String(),
  };

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
    id: json['id'],
    participant1Id: json['participant1_id'],
    participant2Id: json['participant2_id'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    lastMessageContent: json['last_message_content'],
    lastMessageAt: json['last_message_at'] != null
        ? DateTime.parse(json['last_message_at'])
        : null,
  );
}
