import 'package:chat_app_cld/cld%20chat/chat_app_01/Providers/chatProvider.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/MessageServices/localMessage.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/MessageServices/messageRepository.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/MessageServices/remoteMessage.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/authService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Providers/contact-Provider.dart';
import 'addContact.dart';
import 'chatScreen.dart';

class ContactsScreen extends StatefulWidget {
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late final MessageRepository _messageRepo;

  @override
  void initState() {
    super.initState();
    // _messageRepo = MessageRepository(HiveMessageService(), SupabaseMessageService());

    // ✅ Use listen: false to avoid rebuild issues
    Future.microtask(() {
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      contactProvider.loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUserId = auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.pink,
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              print('🔄 Refresh pressed');
              final provider = Provider.of<ContactProvider>(context, listen: false);
              await provider.loadContacts();

              // Optional: log contacts to confirm
              print('✅ Contacts reloaded: ${provider.contacts.length}');
            },
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.person_add),
      //   onPressed: () async {
      //     // Wait until AddContactScreen is popped, then reload
      //     await Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => AddContactScreen()),
      //     );
      //
      //     print('🔁 Returning from AddContact — reloading contacts');
      //     Provider.of<ContactProvider>(context, listen: false).loadContacts();
      //   },
      // ),
      body: Consumer<ContactProvider>(
        builder: (_, provider, __) {
          final contacts = provider.contacts;

          if (contacts.isEmpty) {
            return const Center(child: Text("No contacts found"));
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (_, index) {
              final contact = contacts[index];

              return ListTile(
                title: Text(contact.name ?? "Unknown"),
                subtitle: Text(contact.email ?? ""),
                trailing: contact.isSynced
                    ? const Icon(Icons.cloud_done, color: Colors.green)
                    : const Icon(Icons.cloud_off, color: Colors.grey),

                // ✅ Tap → fast navigation
                onTap: () {
                  // ...
                  try {
                    print('➡️ Attempting to navigate to ChatScreen for ${contact.name}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => ChatProvider(
                            _messageRepo,
                            currentUserId: currentUserId!,
                          ),
                          child: ChatScreen(contact: contact),
                        ),
                      ),
                    );
                  } catch (e) {
                    print('❌ Navigation error: $e');
                  }
                },


                // ✅ Long press delete
                onLongPress: () async {
                  await provider.deleteContact(context, contact.id);
                  await provider.loadContacts();
                },
              );
            },
          );
        },
      ),
    );
  }
}
