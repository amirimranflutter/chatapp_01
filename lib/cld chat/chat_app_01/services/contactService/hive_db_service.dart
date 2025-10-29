import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/DateUtils.dart';
import 'package:hive/hive.dart';
import '../../models/contactModel.dart';

class HiveDBService {

  static const String boxName = 'contactsBox';
  static const String pendingDeleteBoxName = 'pending_deletes';
  // Open Hive box (database)
  Future<Box> _openBox() async => await Hive.openBox(boxName);
  Future<Box> _openPendingDeleteBox() async => await Hive.openBox(pendingDeleteBoxName);
  // Save contact locally
  Future<void> saveContact(ContactModel contact) async {
    final box = await _openBox();
    await box.put(contact.id, contact.toMap());
  }

  // Get all contacts
  Future<List<ContactModel>> getAllContacts() async {
    final box = await _openBox();
    return box.values
        .map((e) => ContactModel.fromMap(Map<String, dynamic>.from(e))).where((c)=>c.userId==currentUserId)
        .toList();
  }

  Future<void> updateSyncStatus(String id, bool isSynced) async {
    final box = await _openBox();
    final existing = box.get(id);
    if (existing == null) return;

    final contactMap = Map<String, dynamic>.from(existing);
    contactMap['isSynced'] = isSynced;

    await box.put(id, contactMap);
  }
  Future<ContactModel?> updateSyncRef(
      String id,{bool? isSync  ,String? contactId,}) async {
    final box = await _openBox();
    final existing = box.get(id);
    if (existing == null) return null;

    final contactMap = Map<String, dynamic>.from(existing);
if(isSync!=null)
    contactMap['isSynced'] = isSync;
if(contactMap!=null)
    contactMap['contactId'] = contactId;

    await box.put(id, contactMap);

    // ✅ Return updated model
    return ContactModel.fromMap(contactMap);
  }


  // Delete contact locally
  Future<void> deleteContact(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
  Future<void> debugPrintAllContacts() async {
    final allContacts = await getAllContacts();

    print("🔍 TOTAL CONTACTS IN HIVE: ${allContacts.length}");
    for (var contact in allContacts) {
      print(
          "📌 Contact => "
              "id: ${contact.id}, "
              "email: ${contact.email}, "
              "isSynced: ${contact.isSynced}, "
              "contactId: ${contact.contactId}"
      );
    }
  }
  Future<void> markPendingDelete(String contactId) async {
    final box = await _openBox();
    final contactMap = box.get(contactId);
    if (contactMap != null) {
      final updated = Map<String, dynamic>.from(contactMap);
      updated['pendingDelete'] = true;
      await box.put(contactId, updated);
    }
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
