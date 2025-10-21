import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/lookprofile.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/supabase_contact_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import '../../models/contactModel.dart';

class HiveDBService {

  static const String boxName = 'contactsBox';

  // Open Hive box (database)
  Future<Box> _openBox() async => await Hive.openBox(boxName);

  // Save contact locally
  Future<void> saveContact(ContactModel contact) async {
    final box = await _openBox();
    await box.put(contact.id, contact.toMap());
  }

  // Get all contacts
  Future<List<ContactModel>> getAllContacts() async {
    final box = await _openBox();
    return box.values
        .map((e) => ContactModel.fromMap(Map<String, dynamic>.from(e)))
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
              "isSynced: ${contact.isSynced}"
      );
    }
  }


  // Update contact sync status
  Future<void> uploadPendingContacts(BuildContext context) async {
    final allContacts = await HiveDBService().getAllContacts();

    for (var contact in allContacts) {
      // Only process contacts that are NOT synced
      if (!contact.isSynced) {
        print('here uploadPending contact 1');
          // 1. Get the profile by email (to find contactId)
          final profile = await ProfileLookupService().getProfileByEmail(contact.email!);
          String? contactId;
          final _currentUser = ProfileLookupService.currentUser;
          if (profile != null) {
            contactId = profile!['id'];
            final exists = await SupabaseContactService()
                .contactExists(_currentUser!.id, contactId!);

            if (exists) {
              await updateSyncStatus(contact.id,true);
              print("⚠️ Contact already exists, marking synced: ${contact.email}");
              await HiveDBService().updateSyncStatus(contact.id, true);
              continue; // ✅ prevents re-upload
            }
            final newContact = ContactModel(
              id: contact.id,
              userId: _currentUser!.id,
              contactId: contactId, // null if not in profile
              email: contact
              .email,
              name: contact.name,
              isSynced: true,
            );
            if (contactId != null) {
              final uploadSuccess = await SupabaseContactService()
                  .uploadContact(context, newContact);
              print('here uploadPending contact ');
              if (uploadSuccess) {
                await updateSyncStatus(newContact.id,true);
                print("✅ Sync status updated after successful upload");
              } else {
                print("⚠️ Upload failed — sync status remains false");
              }
            }
          } else {
            print('⚠️ No profile found for email: ${contact.email}');
            continue; // Skip and don't upload if no profile found
          }
      }
    }

  }

}
