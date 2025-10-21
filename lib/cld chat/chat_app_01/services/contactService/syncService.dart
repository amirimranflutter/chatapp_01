import 'package:flutter/material.dart';
import 'package:chat_app_cld/cld chat/chat_app_01/services/contactService/supabase_contact_service.dart';
import '../../Utils/networkHelpr.dart';
import '../../models/contactModel.dart';
import 'hive_db_service.dart';
import 'lookprofile.dart';

class SyncService {
  final HiveDBService _localDB = HiveDBService();
  final SupabaseContactService _remoteDB = SupabaseContactService();

  /// ✅ Handles: pending contacts, ID-mapping, duplicate prevention, and sync status update
  Future<void> syncContacts(BuildContext context) async {
    final hasNetwork = await NetworkHelper().checkInternet();
    if (!hasNetwork) {
      print("⛔ No internet — skipping sync");
      return;
    }

    final contacts = await _localDB.getAllContacts();
    print("📌 Sync started → Pending contacts: ${contacts.where((c) => !c.isSynced).length}");

    for (var contact in contacts) {
      if (!contact.isSynced) {
        await syncSingleContact(context, contact);
      }
    }
  }

  /// ✅ Single contact sync logic
  Future<void> syncSingleContact(BuildContext context, ContactModel contact) async {
    try {
      // 1️⃣ Get corresponding profile (to fetch contactId)
      final profile = await ProfileLookupService().getProfileByEmail(contact.email!);
      if (profile == null) {
        print("⚠️ Skipping — No profile found for: ${contact.email}");
        return;
      }

      final contactId = profile['id'];
print('contact id --->>>> $contactId');
      // 2️⃣ Prevent duplication in Supabase
      final exists = await _remoteDB.contactExists(contact.userId ?? '', contactId);
      if (exists) {
        print("✅ Already exists on Supabase → Marking synced locally");
        await _localDB.updateSyncRef(contact.id, isSync: true,contactId: contactId );

        return;
      }
      final updateContact=await _localDB.updateSyncRef(contact.id ,contactId: contactId);
      // 3️⃣ Upload with updated contactId
      // final contactId = contact.contactId!;
      final success = await _remoteDB.uploadContact(context, updateContact!);

      if (success) {
        print("✅ Uploaded → Updating Hive");
        await _localDB.updateSyncRef(contact.id,isSync: true);
        print('after syncSingle updater');
        // await _localDB.updateSyncStatus(
        //     contact.contactId = contactId!,
        //     contact.isSynced = true,
        // );
      } else {
        print("❌ Upload failed → Keeping pending");
      }
    } catch (e) {
      print("🔥 Sync error for ${contact.email}: $e");
    }
  }
  Future<void> deleteRemoteContact(BuildContext context, String id) async {
    final hasNetwork = await NetworkHelper().checkInternet();
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
