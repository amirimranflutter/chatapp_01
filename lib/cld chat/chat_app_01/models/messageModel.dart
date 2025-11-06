// models/messageModel.dart

enum MessageStatus {
  sent,
  delivered,
  read;

  String toJson() => name;

  static MessageStatus fromJson(String json) {
    return MessageStatus.values.firstWhere((e) => e.name == json);
  }
}

enum MessageType {
  text,
  image,
  file,
  voice;

  String toJson() => name;

  static MessageType fromJson(String json) {
    return MessageType.values.firstWhere((e) => e.name == json);
  }
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final MessageType messageType;
  final String? fileUrl;
  final bool isDeleted;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.status,
    required this.messageType,
    this.fileUrl,
    this.isDeleted = false,
  });

  /// Create a copy with modified fields (immutable approach)
  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
    MessageType? messageType,
    String? fileUrl,
    bool? isDeleted,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Convert to JSON for storage/API
  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_room_id': chatRoomId,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'status': status.toJson(),
    'message_type': messageType.toJson(),
    'file_url': fileUrl,
    'is_deleted': isDeleted,
  };

  /// Create from JSON
  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    chatRoomId: json['chat_room_id'],
    senderId: json['sender_id'],
    receiverId: json['receiver_id'],
    content: json['content'],
    createdAt: DateTime.parse(json['created_at']),
    status: MessageStatus.fromJson(json['status']),
    messageType: MessageType.fromJson(json['message_type']),
    fileUrl: json['file_url'],
    isDeleted: json['is_deleted'] ?? false,
  );

  @override
  String toString() {
    return 'Message(id: $id, chatRoomId: $chatRoomId, senderId: $senderId, '
        'receiverId: $receiverId, content: $content, createdAt: $createdAt, '
        'status: ${status.name}, messageType: ${messageType.name}, '
        'isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
