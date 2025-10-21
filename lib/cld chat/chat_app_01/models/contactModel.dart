// models/contact_model.dart

class ContactModel {
  String id;          // contact row ID
  String userId;      // current user
  String? contactId;  // linked profile id
  String? name;       // fetched from profile
  String? email;      // fetched from profile
  bool isSynced;

  ContactModel({
    required this.id,
    required this.userId,
    this.contactId,
    this.name,
    this.email,
    this.isSynced = false,
  });

  // Convert to map for local storage
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'contactId': contactId,
    'name': name,
    'email': email,
    'isSynced': isSynced,
  };

  // Create model from map
  factory ContactModel.fromMap(Map<String, dynamic> map) => ContactModel(
    id: map['id'],
    userId: map['userId'],
    contactId: map['contactId'],
    name: map['name'],
    email: map['email'],
    isSynced: map['isSynced'] ?? false,
  );
}
