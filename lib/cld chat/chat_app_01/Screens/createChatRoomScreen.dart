import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chatService.dart';


class CreateChatRoomScreen extends StatefulWidget {
  @override
  _CreateChatRoomScreenState createState() => _CreateChatRoomScreenState();
}

class _CreateChatRoomScreenState extends State<CreateChatRoomScreen> {
  final _nameController = TextEditingController();
  final List<String> _selectedContacts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Chat Room'),
        actions: [
          TextButton(
            onPressed: _selectedContacts.isNotEmpty ? _createChatRoom : null,
            child: Text(
              'Create',
              style: TextStyle(
                color: _selectedContacts.isNotEmpty
                    ? Colors.white
                    : Colors.white54,
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<ChatService,ContactService>(
        builder: (context, chatService, contactService,_) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Chat Room Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: contactService.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contactService.contacts[index];
                    final profile = contact['profiles'];
                    final contactId = profile['id'];
                    final isSelected = _selectedContacts.contains(contactId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            _selectedContacts.add(contactId);
                          } else {
                            _selectedContacts.remove(contactId);
                          }
                        });
                      },
                      title: Text(profile['display_name']),
                      subtitle: Text(profile['email']),
                      secondary: CircleAvatar(
                        child: Text(profile['display_name'][0].toUpperCase()),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createChatRoom() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a chat room name')),
      );
      return;
    }

    final chatService = Provider.of<ChatService>(context, listen: false);
    final error = await chatService.createChatRoom(
      _nameController.text.trim(),
      _selectedContacts,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.pop(context);
    }
  }
}