import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../Providers/contact-Provider.dart';
import '../models/contactModel.dart';
import '../services/contactService/lookprofile.dart';

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

  final _currentUser = ProfileLookupService.currentUser;



  Future<void> _saveContact(BuildContext context) async {
    final email = _emailController.text.trim();

    // Simple email validation using regex
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return; // stop here if invalid
    }

    final contact = ContactModel(
      id: const Uuid().v4(),
      userId: _currentUser!.id,
      contactId: null,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      isSynced: false, // always false on local save
    );
    // In _saveContact
    print("💾 _saveContact called for: ${contact.email}");
    final provider = Provider.of<ContactProvider>(context, listen: false);
    await provider.addContact(contact, context);

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
