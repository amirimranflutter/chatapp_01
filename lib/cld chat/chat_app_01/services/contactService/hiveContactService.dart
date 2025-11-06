import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/DateUtils.dart';
import 'package:hive/hive.dart';
import '../../models/contactModel.dart';

class HiveContactService {

  static const String boxName = 'contactsBox';
  static const String pendingSyncBoxName = 'pending_sync';
  static const String pendingDeleteBoxName = 'pending_deletes';
  // Open Hive box (database)
  Future<Box> _openBox() async => await Hive.openBox(boxName);
  Future<Box> _openPendingSyncBox() async => await Hive.openBox(pendingSyncBoxName);
  Future<Box> _openPendingDeleteBox() async => await Hive.openBox(pendingDeleteBoxName);
  // Save contact locally


  Future<void> savePendingContact(ContactModel contact, String userId) async {
    final box = await _openPendingSyncBox();
    // You can use "${userId}_${contact.id}" as key, or include userId in map
    await box.put('${userId}_${contact.id}', contact.toMap());
    print("🕓 Pending contact saved for user: $userId, email: ${contact.email}");
  }


  Future<void> clearContactBox() async {
    // final box = await _openBox();
    final box = await _openBox();
    await box.clear();
    print("🧹 All data cleared from contactsBox");
  }

  Future<List<ContactModel>> getSyncPendingContacts() async {
    final box = await _openPendingSyncBox();
    return box.values
        .map((item) => ContactModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
// 🗑️ Remove a contact from the pending sync box
  Future<void> removePendingSync(String contactId) async {
    final box = await _openPendingDeleteBox();

    if (box.containsKey(contactId)) {
      await box.delete(contactId);
      print("🗑️ Removed pending contact → $contactId");
    } else {
      print("⚠️ Pending contact not found in box → $contactId");
    }
  }
  Future<void> printPendingSyncBox() async {
    final box = await _openPendingSyncBox();

    if (box.isEmpty) {
      print("📭 Pending Sync Box is empty");
      return;
    }

    print("📋 --- Pending Sync Contacts ---");
    int count = 0;
    final Map<String, int> perUserCounts = {};

    for (var key in box.keys) {
      final data = box.get(key);

      // If using per-user keys like "${userId}_${contactId}"
      String userPart = '';
      if (key is String && key.contains('_')) {
        userPart = key.split('_').first;
      }

      if (data is Map) {
        print("🧑 ID: ${data['id']}, "
            "📧 Email: ${data['email']}, "
            "🆔 contactId: ${data['contact_id'] ?? data['id']}, "
            "✅ isSynced: ${data['is_synced'] ?? false}, "
            "🖼️ avatar: ${data['avatar_url']} "
            "${userPart.isNotEmpty ? '👤 User: $userPart' : ''}");
        count++;
        if (userPart.isNotEmpty) {
          perUserCounts[userPart] = (perUserCounts[userPart] ?? 0) + 1;
        }
      } else {
        print("⚠️ Unexpected data format for key $key → $data");
      }
    }
    print("✅ Total Pending Contacts: $count");
    if (perUserCounts.isNotEmpty) {
      perUserCounts.forEach((user, subCount) {
        print("   - 👤 User $user has $subCount pending");
      });
    }
  }

  Future<void> moveToMainBox(ContactModel contact, String userId) async {
    // 1️⃣ Open both Hive boxes
    final pendingBox = await _openPendingSyncBox();
    final mainBox = await _openBox();

    // 2️⃣ Delete the contact from the pending box
    await pendingBox.delete(contact.id);
    print("🗑️ Deleted from pending box: ${contact.email}");

    // 3️⃣ Get existing contact list for this user (empty if none yet)
    final rawList = mainBox.get('${userId}_contacts', defaultValue: []);
    List<Map<String, dynamic>> contactList = List<Map<String, dynamic>>.from(rawList);

    // 4️⃣ Add the new contact to the list
    contactList.add(contact.toMap());

    // 5️⃣ Save updated contact list back to main box
    await mainBox.put('${userId}_contacts', contactList);

    print("✅ Contact moved to main box for user $userId: ${contact.email}");
  }


  Future<void> printAllContactsForUser(String userId) async {

    print('current user id --->>>${userId}');
    final box = await _openBox();
    final rawList = box.get('${userId}_contacts', defaultValue: []);
    List<Map<String, dynamic>> contactList = List<Map<String, dynamic>>.from(rawList);

    print("📋 All contacts for user $userId:");
    for (var contactMap in contactList) {
      final contact = ContactModel.fromMap(contactMap);
      print("🧑 ID: ${contact.id}, 📧 Email: ${contact.email}, 🆔 ContactID: ${contact.contactId}, AvatarURL: ${contact.avatarUrl}");
    }
    print("📦 Total Contacts: ${contactList.length}");
  }
  Future<void> printPendingSyncBoxForUser(String userId) async {
    final box = await _openPendingSyncBox();

    // Filter only keys belonging to this user
    final userKeys = box.keys.where((key) => key.toString().startsWith('${userId}_')).toList();

    if (userKeys.isEmpty) {
      print("📭 No pending contacts for user $userId");
      return;
    }

    print("📋 --- Pending Sync Contacts for user $userId ---");
    int count = 0;

    for (var key in userKeys) {
      final data = box.get(key);

      if (data is Map) {
        print("🧑 ID: ${data['id']}, "
            "📧 Email: ${data['email']}, "
            "🆔 contactId: ${data['contact_id'] ?? data['id']}, "
            "✅ isSynced: ${data['is_synced'] ?? false}, "
            "🖼️ avatar: ${data['avatar_url']}");
        count++;
      } else {
        print("⚠️ Unexpected data format for key $key → $data");
      }
    }
    print("✅ Total Pending Contacts for $userId: $count");
  }


  Future<List<ContactModel>> getContactsForCurrentUser(String userId) async {
    final box = await _openBox();
    final rawList = box.get('${userId}_contacts', defaultValue: []);
    return List<Map<String, dynamic>>.from(rawList)
        .map(ContactModel.fromMap)
        .toList();
  }
  Future<void> clearContactsBoxForUser(String userId) async {
    final box = await _openBox();
    await box.delete('${userId}_contacts');
    print("🧹 All contacts cleared for user $userId");
  }  Future<void> clearPendingSyncContactsBoxForUser(String userId) async {
    final box = await _openPendingSyncBox();
    await box.delete('${userId}_contacts');
    print("🧹 All contacts cleared for user $userId");
  }
  Future<bool> hasPendingContacts(String userId) async {
    final box = await _openPendingSyncBox();

    // Check for any keys that start with this userId
    final pendingForUser = box.keys.where((key) => key.toString().startsWith('${userId}_'));
    return pendingForUser.isNotEmpty;
  }







  // Delete contact locally
  Future<void> deleteContact(String contactId, String userId) async {
    final box = await _openBox();
    // 1. Retrieve the user's contact list
    final rawList = box.get('${userId}_contacts', defaultValue: []);
    List<Map<String, dynamic>> contactList = List<Map<String, dynamic>>.from(rawList);

    // 3. Save the updated list
    await box.put('${userId}_contacts', contactList);
  }




  Future<void> addPendingDelete(String contactId, String userId) async {
    final box = await _openPendingDeleteBox();
    final key = '${userId}_pendingDeletes';
    final rawSet = box.get(key, defaultValue: []);
    List<String> pendingDeletes = List<String>.from(rawSet);

    if (!pendingDeletes.contains(contactId)) {
      pendingDeletes.add(contactId);
    }

    await box.put(key, pendingDeletes);
    print("🚮 Marked for pending delete for $userId: $contactId");
  }


  Future<List<String>> getPendingDeletes() async {
    final box = await _openPendingDeleteBox();
    return box.keys.cast<String>().toList();
  }

  // 🧹 Clear once successfully deleted remotely
  Future<void> removePendingDelete(String contactId) async {
    final box = await _openPendingDeleteBox();
    await box.delete(contactId);
  }

  Future<void> debugHiveBox(String boxName) async {
    final box = await Hive.openBox(boxName);
    print('🔍 [DEBUG] Contents of Hive box: "$boxName"');
    print('🔑 All keys: ${box.keys}');
    if (box.isEmpty) {
      print('📭 [DEBUG] Box "$boxName" is empty');
      return;
    }
    int count = 0;
    for (var key in box.keys) {
      final value = box.get(key);
      print('🗝️ Key: $key');
      print('    Value: $value');
      count++;
    }
    print('✅ [DEBUG] Box "$boxName" total entries: $count');
  }

  Future<void> findContactIdInBoxes(String contactId, String userId) async {
    // List of relevant boxes and patterns to check
    final boxChecks = [
      {
        'box': await Hive.openBox('contacts'),
        'description': 'Main Contacts',
        'keysToCheck': ['${userId}_contacts'],
        'isList': true,
      },
      {
        'box': await Hive.openBox('pending_sync'),
        'description': 'Pending Sync',
        // User-based key or old style—so we check for both
        'keysToCheck': ['${userId}_$contactId', contactId],
        'isList': false,
      },
      {
        'box': await Hive.openBox('pending_deletes'),
        'description': 'Pending Deletes',
        'keysToCheck': ['${userId}_pendingDeletes'],
        'isList': true,
      },
    ];

    bool found = false;
    print('🔎 Looking for contact ID "$contactId" in all possible boxes...');

    for (var bc in boxChecks) {
      final box = bc['box'] as Box;
      final desc = bc['description'] as String;
      final keysToCheck = bc['keysToCheck'] as List<String>;
      final isList = bc['isList'] as bool;

      for (var key in keysToCheck) {
        if (!box.containsKey(key)) continue;
        final value = box.get(key);

        if (isList) {
          // Check list of maps (contacts or IDs)
          if (value is List) {
            final hit = value.any((item) {
              if (item is Map && item['id'] == contactId) return true;
              if (item is String && item == contactId) return true;
              return false;
            });
            if (hit) {
              print('✅ Found in $desc box, key="$key"');
              found = true;
            }
          }
        } else {
          // Direct map/object key
          if (value is Map && value['id'] == contactId) {
            print('✅ Found in $desc box, key="$key"');
            found = true;
          }
        }
      }
    }
    if (!found) print("❌ Contact ID $contactId not found in any box!");
  }

}
