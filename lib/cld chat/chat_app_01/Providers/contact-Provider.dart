import 'package:flutter/cupertino.dart';

import '../models/contactModel.dart';
import '../services/contactService/hive_db_service.dart';
import '../services/contactService/syncService.dart';

class ContactProvider with ChangeNotifier {
  final HiveDBService _localDB = HiveDBService();
  final SyncService _syncService = SyncService();

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

  Future<void> uploadPendingContacts(BuildContext context) async {
    await _syncService.syncContacts(context);
    await loadContacts();


  }

  // Future<void> deleteContact(ContactModel contact, BuildContext context) async {
  //   await _localDB.deleteContact(contact.id);
  //   notifyListeners();
  //   await _syncService.syncContacts(context);
  // }
  Future<void> deleteContact(BuildContext context, String contactId) async {
    try {
      await _localDB.deleteContact(contactId);   // ✅ Remove from Hive
      notifyListeners();                        // ✅ Refresh UI

      // Now sync delete to Supabase
      await _syncService.deleteRemoteContact(context, contactId);
    } catch (e) {
      print("❌ Local delete failed: $e");
    }
  }

}
