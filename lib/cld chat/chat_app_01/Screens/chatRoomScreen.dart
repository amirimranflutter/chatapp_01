import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/chatService.dart';
import 'chatScreen.dart';

class ChatRoomsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (context, chatService, _) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: chatService.chatRooms.length,
                itemBuilder: (context, index) {
                  final chatRoom = chatService.chatRooms[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(chatRoom['type'] == 'group'
                          ? Icons.group
                          : Icons.person),
                    ),
                    title: Text(chatRoom['name'] ?? 'Direct Chat'),
                    subtitle: Text(
                      'Created by ${chatRoom['profiles']['display_name']}',
                    ),
                    trailing: Text(
                      DateFormat('MMM dd').format(
                        DateTime.parse(chatRoom['created_at']),
                      ),
                    ),
                    onTap: () {
                      chatService.setCurrentChat(chatRoom['id']);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen()),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
