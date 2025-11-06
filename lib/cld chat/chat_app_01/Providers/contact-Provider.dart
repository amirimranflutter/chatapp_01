import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../AuthServices/authSyncService.dart';
import '../models/contactModel.dart';
import '../services/contactService/hiveContactService.dart';
import '../services/contactService/syncContactService.dart';

class ContactProvider with ChangeNotifier {
  final HiveContactService _localDB = HiveContactService();
  final SyncContactService _syncService = SyncContactService();

  List<ContactModel> _contacts = [];
  List<ContactModel> get contacts => _contacts;

  Future<void> loadContacts(String userId) async {
  //   _contacts = await _localDB.getAllContacts();
  _contacts = await HiveContactService().getContactsForCurrentUser(userId);
  _contacts=contacts;
    notifyListeners();
  }


  Future<void> addContact(ContactModel contact, BuildContext context) async {
    final currenUserID = Provider.of<AuthSyncService>(context, listen: false).getUserId();

    // 1️⃣ Save to pending sync box (local draft)
    await _localDB.savePendingContact(contact, currenUserID.toString());

    // 2️⃣ Add to UI list (instant feedback)
    _contacts.add(contact);
    notifyListeners();

    print("📥 addContact saved locally & pending: ${contact.email}");

    // 3️⃣ Print pending box for debug
    await _localDB.printPendingSyncBoxForUser(currenUserID.toString());
    // 4️⃣ Start auto-sync process (listener)
    GlobalSyncManager.startSyncListener(context);

    // 5️⃣ One-time sync check after delay (app startup or add)
    Future.delayed(const Duration(seconds: 1), () async {
      final hasNetwork = await GlobalSyncManager.checkInternet();
      final hasPending = await HiveContactService().hasPendingContacts(currenUserID.toString());

      if (hasPending && hasNetwork) {
        print("🚀 Pending contacts found — starting sync now...");
        await syncContacts(context);
      } else {
        print("💤 No pending contacts or offline — skipping sync");
      }
    });
  }

  Future<void> syncContacts(BuildContext context) async {
    await _syncService.syncContacts(context);
    final userId = Provider.of<AuthSyncService>(context, listen: false).getUserId();
    await loadContacts(userId.toString());

  }




  Future<void> deleteContact(BuildContext context, String contactId) async {
    try {
      final hasNetwork = await GlobalSyncManager.checkInternet();
      // Get the current logged-in user's userId
      final userId = Provider.of<AuthSyncService>(context, listen: false).getUserId();

      // 1️⃣ Always delete locally (from the user's contact list)
      await _localDB.deleteContact(contactId, userId.toString()); // <-- Implemented below
      _contacts = await _localDB.getContactsForCurrentUser(userId.toString());
      notifyListeners();

      // 2️⃣ If no network, add to pending deletes for this user!
      if (!hasNetwork) {
        await _localDB.addPendingDelete(contactId, userId.toString());
        print("⚠️ Offline — stored for later deletion sync");
        return;
      }

      // 3️⃣ If online, sync deletion to Supabase
      await _syncService.deleteRemoteContact(context, contactId);
      print("🗑️ Deleted from both Hive & Supabase");
    } catch (e) {
      print("❌ Delete failed: $e");
    }
  }


}
