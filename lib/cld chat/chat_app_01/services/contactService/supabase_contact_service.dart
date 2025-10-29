// services/supabase_contact_service.dart
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Utils/globalSyncManager.dart';
import '../../Utils/showSnackBar.dart';
import '../../models/contactModel.dart';
import 'hive_db_service.dart';

class SupabaseContactService {
  final supabase = Supabase.instance.client;
  final String contactTable = 'contacts';
  final String profileTable = 'profiles';
  final _localDB=HiveDBService();
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
