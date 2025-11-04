import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:flutter/cupertino.dart';

import '../models/contactModel.dart';
import '../services/contactService/hive_db_service.dart';
import '../services/contactService/syncService.dart';

class ContactProvider with ChangeNotifier {
  final HiveDBService _localDB = HiveDBService();
  final SyncContactService _syncService = SyncContactService();

  List<ContactModel> _contacts = [];
  List<ContactModel> get contacts => _contacts;

  Future<void> loadContacts() async {
    _contacts = await _localDB.getAllContacts();
    notifyListeners();
  }

  Future<void> addContact(ContactModel contact, BuildContext context) async {
    await _localDB.savePendingContact(contact);
// In addContact
    print("📥 addContact saving locally: ${contact.email}");
    _contacts.add(contact);

    notifyListeners();
    await _localDB.printPendingSyncBox();
    GlobalSyncManager.startSyncListener(context);

    // ✅ Trigger one-time sync check when app opens
    Future.delayed(const Duration(seconds: 1), () async {
      final hasInternet = await GlobalSyncManager.checkInternet();
      final hasPending = await HiveDBService().hasPendingContacts();

    if (hasPending && hasInternet) {
      print("🚀 Pending contacts found — starting sync now...");
      syncContacts(context);
    } else {
      print("💤 No pending contacts or offline — skipping startup sync");
    }  });
  }
  Future<void> syncContacts(BuildContext context) async {
    await _syncService.syncContacts(context);
    await loadContacts(); // refresh UI with updated local data
  }




  Future<void> deleteContact(BuildContext context, String contactId) async {
    try {
      final hasNetwork = await GlobalSyncManager.checkInternet();

      // 1️⃣ Always delete locally (so UI updates)
      await _localDB.deleteContact(contactId);
      _contacts = await _localDB.getAllContacts();
      notifyListeners();

      // 2️⃣ If no network, store for later sync
      if (!hasNetwork) {
        await _localDB.addPendingDelete(contactId);
        print("⚠️ Offline — stored for later deletion sync");
        return;
      }

      // 3️⃣ Online: delete immediately from Supabase
      await _syncService.deleteRemoteContact(context, contactId);
      print("🗑️ Deleted from both Hive & Supabase");
    } catch (e) {
      print("❌ Delete failed: $e");
    }
  }


}
