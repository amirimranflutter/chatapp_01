import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../Providers/contact-Provider.dart';
import '../models/contactModel.dart';
import '../services/contactService/hive_db_service.dart';
import '../services/contactService/lookprofile.dart';
import '../services/contactService/supabase_contact_service.dart';
import '../Utils/showSnackBar.dart';
import '../services/contactService/syncService.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final uuid = Uuid();
  final _localDB = HiveDBService();
  final _remoteDB = SupabaseContactService();
  final _syncService = SyncService();
  final _profileLookup = ProfileLookupService();
  final _currentUser = ProfileLookupService.currentUser;

  // Future<void> _saveContact() async {
  //   final name = _nameController.text.trim();
  //   final email = _emailController.text.trim();
  //
  //   if (name.isEmpty || email.isEmpty || !email.contains('@')) {
  //     SnackbarService.showError(context, "Please enter valid name & email");
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     // Lookup profile by email
  //     final profile = await _profileLookup.getProfileByEmail(email);
  //     String? contactId;
  //
  //     if (profile != null) contactId = profile['id'];
  //
  //     final newContact = ContactModel(
  //       id: uuid.v4(),
  //       userId: _currentUser!.id,
  //       contactId: contactId, // null if not in profile
  //       email: email,
  //       name: name,
  //       isSynced: false,
  //     );
  //
  //     await _localDB.saveContact(newContact);
  //
  //     // Try online sync if contact exists in profile
  //     if (contactId != null) {
  //       final uploadSuccess = await _remoteDB.uploadContact(context, newContact);
  //
  //       if (uploadSuccess) {
  //         await _localDB.updateSyncStatus(newContact.id, true);
  //         print("✅ Sync status updated after successful upload");
  //       } else {
  //         print("⚠️ Upload failed — sync status remains false");
  //       }
  //     }
  //
  //
  //     SnackbarService.showSuccess(context, "Contact saved successfully");
  //     Navigator.pop(context);
  //   } catch (e) {
  //     SnackbarService.showError(context, "Failed to save contact: $e");
  //     print("❌ AddContactScreen error: $e");
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _saveContact(BuildContext context) async {
    final contact = ContactModel(
      id: const Uuid().v4(),
      userId: _currentUser!.id,
      contactId: null,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      isSynced: false, // always false on local save
    );
    final provider = Provider.of<ContactProvider>(context, listen: false);
    await provider.addContact(contact, context);
    //
    // await HiveDBService().saveContact(contact); // ✅ Save to local Hive first
    //
    // // Try sync immediately after saving
    // await SyncService().syncContacts(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Contact")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async{
                      await _saveContact(context);
                      Navigator.pop(context);
                    },
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Contact"),
            ),
          ],
        ),
      ),
    );
  }
}
