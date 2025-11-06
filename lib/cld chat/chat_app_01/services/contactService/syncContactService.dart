import 'package:chat_app_cld/cld%20chat/chat_app_01/AuthServices/authLocalService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/DateUtils.dart';
import 'package:flutter/material.dart';
import 'package:chat_app_cld/cld chat/chat_app_01/services/contactService/supabase_contact_service.dart';
import 'package:provider/provider.dart';
import '../../AuthServices/authSyncService.dart';
import '../../Utils/globalSyncManager.dart';
import 'hiveContactService.dart';

class SyncContactService {
  final HiveContactService _localDB = HiveContactService();
  final SupabaseContactService _remoteDB = SupabaseContactService();
  final currentuser=AuthSyncService().getCurrentUser();
  final CurrentUserId=AuthLocalService().getCurrentUser()!.id;
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

        await _localDB.moveToMainBox(updatedContact, currentUser!.id);

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
        await _localDB.deleteContact(contactId,currentUser!.id);

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
