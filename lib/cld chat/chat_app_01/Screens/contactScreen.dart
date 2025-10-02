import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chatService.dart';
import 'chatScreen.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _emailController = TextEditingController();
  String _searchQuery = "";
  bool _isContactLoaded = false;
  void didChangeDependencies() {
    super.didChangeDependencies();
    // run only once
    if (!_isContactLoaded) {
      Provider.of<ContactService>(context, listen: false).loadContacts();
      _isContactLoaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<ChatService,ContactService>(
      builder: (context, chatService,contactService ,_) {
        final filteredContacts = contactService.contacts.where((contact) {
          final profile = contact['profile'];
          final name = (profile['display_name'] ?? "").toString().toLowerCase();
          final email = (profile['email'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase());
        }).toList();

        return Container(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              // ✅ Add contact field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter email to add contact',
                          filled: true,
                          fillColor: theme.colorScheme.secondaryContainer,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (_emailController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('First insert email')),
                          );
                        }
                        final error = await chatService
                            .addContact(_emailController.text);
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        } else {
                          _emailController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Contact added successfully')),
                          );
                        }
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.secondaryContainer,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Contacts List
              Expanded(
                child: filteredContacts.isEmpty
                    ? Center(
                  child: Text(
                    'No contacts found',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final profile = contact['profile'];
                    final avatarUrl = profile['avatar_url'];
                    final displayName =
                        profile['display_name'] ?? 'Unknown';
                    final email = profile['email'] ?? '';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        onTap: () async {
                          final profile =
                          contact['profile'] as Map<String, dynamic>;
                          if (profile == null) {
                            print(
                              "Profile is null for contact: $contact",
                            );
                            return;
                          }
                          final profileId = profile['id'] as String;
                          if (profileId == null) {
                            print(
                              "Profile ID is null for profile: $profile",
                            );
                            return;
                          }
                          final chatService = Provider.of<ChatService>(
                            context,
                            listen: false,
                          );
                          await chatService.createDirectChat(profileId);

                          // Navigate to ChatScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(), // your existing ChatScreen
                            ),
                          );
                        },
                        onLongPress: () {
                          final removeContactId = contact['contact_id'];
                          _showContactOptions(
                              profile, chatService, removeContactId,contactService);
                        },
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(displayName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.8),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.message_rounded),
                          onPressed: () async {
                            await chatService.createDirectChat(
                              profile['id'],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Bottom Sheet Options
  void _showContactOptions(profile, ChatService chatService, removeContactId,ContactService contactService) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Start Chat'),
                onTap: () async {
                  Navigator.pop(context);
                  // await chatService.createDirectChat(profile['id']);
                },
              ),
              ListTile(
                  leading: Icon(Icons.delete, color: theme.colorScheme.error),
                  title: Text(
                    'Remove Contact',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    contactService.removeContact(removeContactId);
                    Navigator.pop(context);
                  }
              ),
            ],
          ),
        );
      },
    );
  }
}
