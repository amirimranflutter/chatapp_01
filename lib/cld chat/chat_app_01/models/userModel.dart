class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      displayName: map['display_name'],
      email: map['email'],
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// models/message_model.dart
