import 'package:chat_app_cld/cld%20chat/chat_app_01/Providers/chatProvider.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/chatScreen.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/DateUtils.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/localChatRoomService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/MessageServices/localMessage.dart';
import 'package:flutter/material.dart';

import '../services/contactService/lookprofile.dart';
class ChatContactListScreen extends StatefulWidget {
  @override
  _ChatContactListScreenState createState() => _ChatContactListScreenState();
}

class _ChatContactListScreenState extends State<ChatContactListScreen> {
  List<ChatRoomModel> chatRooms = [];
  Map<String, MessageModel?> lastMessages = {};

  @override
  void initState() {
    super.initState();

    loadChats();
  }

  Future<void> loadChats() async {
    final currentUserId = ProfileLookupService.currentUser!.id;

    // 1. Fetch chat rooms where user is a participant
    chatRooms = await HiveChatRoomService().fetchChatRoomsForUser(currentUserId);

    // 2. For each room, fetch last message
    for (final room in chatRooms) {
      final message = await HiveMessageService().fetchLastMessage(room.id);
      lastMessages[room.id] = message;
    }
    setState(() {});
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (chatRooms.isEmpty) {
      return const Center(child: Text('No chats yet'));
    }

    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        final message = lastMessages[chatRoom.id];
        final currentUser = ProfileLookupService.currentUser!;

        // 👇 Use FutureBuilder for async contact lookup
        return FutureBuilder<String>(
          future: chatRoom.otherParticipantName(currentUser.id),
          builder: (context, snapshot) {
            // Handle loading/error states
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircularProgressIndicator(),
                title: Text("Loading..."),
              );
            }
            if (snapshot.hasError) {
              return ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: Text('Error: ${snapshot.error}'),
              );
            }

            final displayName = snapshot.data ?? 'Unknown User';

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(displayName),
              subtitle: Text(message?.content ?? 'No messages yet'),
              trailing: Text(
                message != null
                    ? DateUtilities.formatTimestamp(message.createdAt)
                    : '',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => ChatScreen(
                //       chatId: chatRoom.id,
                //       contactName: displayName,
                //     ),
                //   ),
                // );
              },
            );
          },
        );
      },
    );
  }

}


