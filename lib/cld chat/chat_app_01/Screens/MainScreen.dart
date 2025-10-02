import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/authService.dart';
import '../services/chatService.dart';
import 'chatRoomScreen.dart';
import 'chatScreen.dart';
import 'contactScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final contactService = Provider.of<ContactService>(context, listen: false);
      contactService.loadContacts();
      chatService.loadChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chating'),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthService>(context, listen: false).signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: _currentIndex == 0
          ? ChatRoomsScreen()
          : ContactsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }

}
