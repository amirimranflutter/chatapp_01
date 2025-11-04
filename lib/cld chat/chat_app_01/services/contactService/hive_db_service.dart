import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/DateUtils.dart';
import 'package:hive/hive.dart';
import '../../models/contactModel.dart';

class HiveDBService {

  static const String boxName = 'contactsBox';
  static const String pendingSyncBoxName = 'pending_sync';
  static const String pendingDeleteBoxName = 'pending_deletes';
  // Open Hive box (database)
  Future<Box> _openBox() async => await Hive.openBox(boxName);
  Future<Box> _openPendingSyncBox() async => await Hive.openBox(pendingSyncBoxName);
  Future<Box> _openPendingDeleteBox() async => await Hive.openBox(pendingDeleteBoxName);
  // Save contact locally
  Future<void> saveContact(ContactModel contact) async {
    final box = await _openBox();
    await box.put(contact.id, contact.toMap());
  }
  Future<void> savePendingContact(ContactModel contact) async {
    final box = await _openPendingSyncBox();
    await box.put(contact.id, contact.toMap());
    print("🕓 Contact saved in pending sync: ${contact.email}");
  }
  Future<void> clearContactsBox() async {
    final box = await _openBox();

    await box.clear();
    print("🧹 All data cleared from contactsBox");
  }
  Future<void> clearPendingSyncContactsBox() async {
    // final box = await _openBox();
    final box = await _openPendingSyncBox();
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

  Future<void> moveToMainBox(ContactModel contact) async {
    final pendingBox = await _openPendingSyncBox();
    final mainBox = await _openBox();

    // Remove from pending
    await pendingBox.delete(contact.id);
// In moveToMainBox
    print("📦 moveToMainBox called for: ${contact.email}");
    // Save to main contacts box
    await mainBox.put(contact.id, contact.toMap());

    print("✅ Contact moved to main box after sync: ${contact.email}");
  }
  Future<void> printAllContacts() async {
    final _box = await _openBox();
    print("📋 --- All Contacts in Hive ---");

    for (var raw in _box.values) {
      final contact = raw is ContactModel
          ? raw
          : ContactModel.fromMap(Map<String, dynamic>.from(raw));

      print("🧑 ID: ${contact.id}, 📧 Email: ${contact.email}, 🆔 contactID: ${contact.contactId ?? 'null'},avatarurl: ${contact.avatarUrl??'null'}");
    }

    print("📦 Total Contacts: ${_box.length}");
  }
  Future<void> printPendingSyncBox() async {
    final box = await _openPendingSyncBox();

    if (box.isEmpty) {
      print("📭 Pending Sync Box is empty");
      return;
    }

    print("📋 --- Pending Sync Contacts ---");
    for (var key in box.keys) {
      final data = box.get(key);

      if (data is Map) {
        print("🧑 ID: ${data['id']}, "
            "📧 Email: ${data['email']}, "
            "🆔 contactId: ${data['contact_id']}, "
            "✅ isSynced: ${data['is_synced']}, "
            "🖼️ avatar: ${data['avatar_url']}");
      } else {
        print("⚠️ Unexpected data format for key $key → $data");
      }
    }

    print("✅ Total Pending Contacts: ${box.length}");
  }

  // Get all contacts
  Future<List<ContactModel>> getAllContacts() async {
    final box = await _openBox();
    return box.values
        .map((e) => ContactModel.fromMap(Map<String, dynamic>.from(e))).where((c)=>c.userId==currentUserId)
        .toList();
  }
  Future<bool> hasPendingContacts() async {
    final box = await _openPendingSyncBox();
    return box.isNotEmpty;
  }





  Future<ContactModel?> getContactByContactId(String contactId) async {
    final box = await _openBox(); // returns the Hive box where you store contacts

    try {
      // iterate to avoid firstWhere/orElse null problem
      for (var value in box.values) {
        final contact = value is ContactModel ? value : null;
        if (contact != null && contact.contactId == contactId) {
          return contact;
        }
      }
      return null; // not found
    } catch (e, st) {
      print('❌ getContactByContactId error: $e\n$st');
      return null;
    }
  }

  // Delete contact locally
  Future<void> deleteContact(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }



  Future<void> addPendingDelete(String contactId) async {
    final box = await _openPendingDeleteBox();
    await box.put(contactId, true); // value doesn’t matter, just a flag
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

}
