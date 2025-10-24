import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/addContact.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/databaseServices/authService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/chatRoomService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/lookprofile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/contact-Provider.dart';
import 'chatScreen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add New Contact",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddContactScreen()),
              );
            },
          ),
          IconButton(onPressed: (){
            AuthService().signOut();

          }, icon: Icon(Icons.logout_rounded))
        ],
      ),
      body: Consumer<ContactProvider>(
        builder: (context, provider, child) {
          final contacts = provider.contacts;

          if (contacts.isEmpty) {
            return const Center(
              child: Text(
                "No contacts found",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const Divider(height: 2),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                title: Text(contact.name ?? "Unknown"),
                subtitle: Text(contact.email ?? ""),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  // Replace `ContactModel` and `chatProvider` with your app’s types
                  onTap: () async {
                    final contactId = contact.userId;             // The profile id of the contact
                    final currentUserId = ProfileLookupService.currentUser!.id;

                    // Find or create chat room
                    String chatId = await ChatRoomService().findOrCreateChatRoom(currentUserId, contactId);

                    // Navigate to chat screen, passing chatId
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          contactName: contact.name!,
                          chatId: chatId,
                        ),
                      ),
                    );
                  },

                  onLongPress: () => provider.deleteContact(context, contact.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Add Contact"),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
