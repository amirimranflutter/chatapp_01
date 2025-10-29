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
    await _localDB.saveContact(contact);
    _contacts.add(contact);
    notifyListeners();
    try {
      await _syncService.syncSingleContact(context, contact);
    } catch (e) {
      print("Sync error: $e");
    } // Upload if possible
  }



  // Future<void> deleteContact(ContactModel contact, BuildContext context) async {
  //   await _localDB.deleteContact(contact.id);
  //   notifyListeners();
  //   await _syncService.syncContacts(context);
  // }
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
