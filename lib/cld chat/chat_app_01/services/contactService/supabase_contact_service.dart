// services/supabase_contact_service.dart
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/lookprofile.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Utils/globalSyncManager.dart';
import '../../Utils/showSnackBar.dart';
import '../../models/contactModel.dart';
import 'hiveContactService.dart';

class SupabaseContactService {
  final supabase = Supabase.instance.client;
  final String contactTable = 'contacts';
  final String profileTable = 'profiles';
  final _localDB=HiveContactService();
  // Upload a new contact
  Future<bool> uploadContact(BuildContext context, ContactModel contact) async {
    try {
      final hasNetwork = await GlobalSyncManager.checkInternet();
      if (!hasNetwork) {
        print("⚠️ No internet — skipping Supabase upload");
        return false;
      }


      await supabase.from(contactTable).upsert({
        'id': contact.id,
        'user_id': contact.userId,
        'contact_id': contact.contactId,
      });

      print("✅ Contact uploaded successfully");
      return true;  // ✅ only when success
    } catch (e) {
      print("❌ Upload failed in uploadContact in supbabase service supa_contactService=>uploadContact: $e");
      SnackbarService.showError(context, "Failed to upload contact: ");
      return false; // ✅ prevents marking as synced
    }
  }
  Future<bool> contactExists(String userId, String contactId) async {
    try {
      final existing = await supabase
          .from('contacts')
          .select('id')
          .eq('user_id', userId)
          .eq('contact_id', contactId)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      print("❌ Error checking existing contact: in catch of contactExit");
      return false;
    }
  }



  // 🔴 Delete contact
  Future<void> deleteContact(BuildContext context, String id) async {
    try {
      print("🗑️ Deleting contact with ID: $id");

      // 1️⃣ Debug: Check if the contact exists BEFORE delete
      final debug = await supabase
          .from(contactTable)
          .select()
          .eq('id', id);
      print("🔍 Matching row in Supabase: $debug");

      // 2️⃣ Attempt delete
      final response = await supabase
          .from(contactTable)
          .delete()
          .eq('id', id);

      print("✅ Delete response: $response");
      SnackbarService.showSuccess(context, "Contact deleted from Supabase");
    } catch (e) {
      print("❌ Failed to delete contact in SupabaseContactService deleteContact $e");
      // SnackbarService.showError(context, "Failed to delete contact: $e");
    }
  }
  Future<ContactModel?> fetchMapAndUpload(ContactModel contact) async {
    try {
      print("🔹 Starting fetchMapAndUpload for: ${contact.email}");
      print("Initial contact data: id=${contact.id}, userId=${contact.userId}, contactId=${contact.contactId}");

      // 🧩 1️⃣ Validate
      if (contact.email == null || contact.email!.isEmpty) {
        print("⚠️ Contact email is missing — cannot fetch profile.");
        return null;
      }

      print("🔍 Fetching profile for email: ${contact.email}");

      // 🧠 2️⃣ Fetch profile by email
      final profile = await ProfileLookupService().getProfileByEmail(contact.email!);
      print("📥 Raw profile response: $profile");

      if (profile == null) {
        print("❌ No profile found for ${contact.email}");
        return null;
      }

      // 🧠 3️⃣ Extract profile data
      final profileId = profile['id'] as String?;
      final avatarUrl = profile['avatar_url'] as String?;

      if (profileId == null) {
        print("⚠️ Profile found but missing ID for ${contact.email}");
        return null;
      }
// In fetchMapAndUpload
      print("🔹 fetchMapAndUpload for: ${contact.email}");
      // 🧠 4️⃣ Update local contact model
      contact.contactId = profileId;
      contact.avatarUrl = avatarUrl;
      contact.isSynced = true;


      // 🧩 5️⃣ Check if contact already exists on Supabase
      final existing = await supabase
          .from('contacts')
          .select('id')
          .eq('id', contact.id)
          .eq('contact_id', contact.contactId!)
          .maybeSingle();


      if (existing != null) {
        print("⚠️ Contact already exists on Supabase for ${contact.email}");
        return contact;
      }

      // 🧩 6️⃣ Upload contact to Supabase
      final response = await supabase.from('contacts').insert({
        'id': contact.id,
        'user_id': contact.userId,
        'contact_id': contact.contactId,
      });

      print("✅ Contact uploaded successfully: ${contact.email}");
      print("📦 Supabase response: $response");

      return contact;

    } catch (e, st) {
      print("🔥 Error in fetchMapAndUpload: $e");
      return null;
    }
  }


  // 🔍 Fetch contacts with profile info
  Future<List<ContactModel>> fetchContactsWithProfiles(BuildContext context, String userId) async {
    try {
      print("📡 Fetching contacts for userId: $userId");

      final response = await supabase
          .from(contactTable)
          .select('id, user_id, contact_id, profiles(name, email)')
          .eq('user_id', userId);

      print("📥 Raw response: $response");

      final contacts = (response as List)
          .map((data) => ContactModel(
        id: data['id'],
        userId: data['user_id'],
        contactId: data['contact_id'],
        name: data['profiles']?['name'],
        email: data['profiles']?['email'],
      ))
          .toList();

      print("✅ Parsed contacts: ${contacts.length}");
      SnackbarService.showSuccess(context, "Contacts fetched successfully");

      return contacts;
    } catch (e) {
      print("❌ Failed to fetch contacts: $e");
      SnackbarService.showError(context, "Failed to fetch contacts: $e");
      return [];
    }
  }


}
