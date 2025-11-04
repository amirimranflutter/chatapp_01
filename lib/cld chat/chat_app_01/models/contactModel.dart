import 'package:hive/hive.dart';

part 'contactModel.g.dart';

@HiveType(typeId: 1)
class ContactModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? userId;

  @HiveField(2)
   String? contactId; // Reference to profile (Supabase)

  @HiveField(3)
  final String? name;

  @HiveField(4)
  final String? email;

  @HiveField(5)
   bool isSynced;

  // ✅ Local-only field (not uploaded to Supabase)
  @HiveField(6)
   String? avatarUrl;

  ContactModel({
    required this.id,
    this.userId,
    this.contactId,
    this.name,
    this.email,
    this.isSynced = false,
    this.avatarUrl,
  });

  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
    id: map['id'],
    userId: map['user_id'],
    contactId: map['contact_id'],
    name: map['name'],
    email: map['email'],
    isSynced: map['is_synced'] ?? false,
    avatarUrl: map['avatar_url'], // won't exist remotely, stays null
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'contact_id': contactId,
    'name': name,
    'email': email,
    'is_synced': isSynced,
    'avatar_url':avatarUrl,
    // ⚠️ do NOT send avatarUrl to Supabase
  };


}
