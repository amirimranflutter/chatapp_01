import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/AuthServices/authLocalService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/AuthServices/authSyncService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/addContact.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/chatScreen.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/auth/authScreen.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/syncService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/hiveContactService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/lookprofile.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/syncContactService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/contact-Provider.dart';
import '../services/ChatRoomService/localChatRoomService.dart';
import '../services/ChatRoomService/supabaseChatRoomService.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final currrentUserID=AuthLocalService().getCurrentUser();
  final syncService = ChatRoomSyncService(
    HiveChatRoomService(),
    SupabaseChatRoomService(),
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<AuthSyncService>(context, listen: false).getUserId();
      Provider.of<ContactProvider>(context, listen: false).loadContacts(userId.toString());
    });
  }
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
          IconButton(
            onPressed: () {
              AuthSyncService().signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>AuthScreen()));
            },
            icon: Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Consumer<ContactProvider>(
        builder: (context, provider, child) {
          final contacts = provider.contacts;

          if (contacts.isEmpty) {
            return const Center(
              child: Text("No contacts found", style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.separated(
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const Divider(height: 2),
            itemBuilder: (context, index) {
              final contact = contacts[index];


              return ListTile(
                leading: contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                    ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: contact.avatarUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                )
                    : CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  radius: 24,
                  child: Text(
                    (contact.name != null && contact.name!.isNotEmpty)
                        ? contact.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                title: Text(contact.name ?? "Unknown"),
                subtitle: Text(contact.email ?? ""),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () async {
                  final contactId = contact.contactId.toString();
                  final currentUserId = ProfileLookupService.currentUser!.id;

                  print('Tapped contact -> Name: ${contact.name}');
                  print('Tapped contact -> Email: ${contact.email}');
                  print('Tapped contact -> ContactID: ${contact.contactId}');

                  // String chatId = await HiveChatRoomService()
                  //     .findOrCreateChatRoom(currentUserId, contactId);
                  String chatId =await syncService.findOrCreateChatRoom(currentUserId, contactId);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(contact: contact, chatId: chatId),
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
          
          // HiveContactService().clearContactsBoxForUser(currrentUserID.toString());
          // HiveContactService().clearPendingSyncContactsBoxForUser(currrentUserID.toString());

          HiveContactService().printAllContactsForUser(currrentUserID!.id);
          // HiveContactService().debugHiveBox('contactsBox');
          // HiveContactService().findContactIdInBoxes('e6c4a579-dd79-480d-9b5f-cf36e7da7f05','ebe74a4f-cb07-47fb-a07f-894c994c9dbc');
         // print('currentUser is ---->>> $user');
         //  HiveContactService().printPendingSyncBoxForUser(currrentUserID.toString());
          // SyncContactService().syncContacts(context);
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const AddContactScreen()),
          // );
        },
        icon: const Icon(Icons.person_add),
        label: const Text("Add Contact"),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
