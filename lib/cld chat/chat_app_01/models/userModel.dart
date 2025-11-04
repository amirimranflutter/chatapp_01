import 'package:hive/hive.dart';

part 'userModel.g.dart';


@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] ?? '',
    email: map['email'] ?? '',
    displayName: map['display_name'] ?? '',
    avatarUrl: map['avatar_url'],
    createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };
}
