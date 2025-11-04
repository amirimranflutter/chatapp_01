import 'package:flutter/material.dart';
import 'package:chat_app_cld/cld chat/chat_app_01/services/contactService/supabase_contact_service.dart';
import '../../Utils/globalSyncManager.dart';
import 'hive_db_service.dart';

class SyncContactService {
  final HiveDBService _localDB = HiveDBService();
  final SupabaseContactService _remoteDB = SupabaseContactService();

  /// ✅ Handles: pending contacts, ID-mapping, duplicate prevention, and sync status update
  Future<void> syncContacts(BuildContext context) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      print("⛔ No internet — skipping sync");
      return;
    }

    final pendingContacts = await _localDB.getSyncPendingContacts();
    print("🔄 syncContacts running, pending count: ${pendingContacts.length}");
    for (var contact in pendingContacts) {
      final updatedContact = await _remoteDB.fetchMapAndUpload( contact);
      if (updatedContact!=null) {
        await _localDB.moveToMainBox(updatedContact);

      }
    }

  }
  Future<void> syncPendingDeletes(BuildContext context) async {
    final pendingDeleteIds = await _localDB.getPendingDeletes();

    for (final contactId in pendingDeleteIds) {
      try {
        // 🗑️ Try deleting from remote Supabase
        await _remoteDB.deleteContact(context, contactId);

        // 🧹 Once successful, remove from pending deletes box
        await _localDB.removePendingDelete(contactId);

        // ✅ Also ensure it's gone from local Hive contacts box
        await _localDB.deleteContact(contactId);

        print("🗑️ Synced delete: $contactId");
      } catch (e) {
        print("❌ Delete sync failed for contactId $contactId: $e");
      }
    }
  }






  Future<void> deleteRemoteContact(BuildContext context, String id) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      print("⚠️ No internet — will retry later");
      return;
    }

    try {
      await _remoteDB.deleteContact(context, id);
      print("🗑️ Deleted from Supabase: $id");
    } catch (e) {
      print("❌ Remote delete failed: $e");
    }
  }

}
