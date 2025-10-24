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
  Widget build(BuildContext context) {

    if (chatRooms.isEmpty) {
      return Center(child: Text('No chats yet'));
    }

    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        final message = lastMessages[chatRoom.id];

        final currentUser = ProfileLookupService.currentUser;
        if (currentUser == null) {
          return const SizedBox(); // or any placeholder UI
        }

        String displayName = chatRoom.type == 'group'
            ? (chatRoom.name ?? 'Group Chat')
            : chatRoom.otherParticipantName(currentUser.id);

        return ListTile(
          leading: Icon(Icons.person),
          title: Text(displayName),
          subtitle: Text(message?.text ?? 'No messages yet'),
          trailing: Text(
            message != null
                ? DateUtilities.formatTimestamp(message.createdAt)
                : '',
            style: TextStyle(fontSize: 12),
          ),
          onTap: () {
            // Navigate to chat screen
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatRoom.id,
                contactName:  displayName,
              ),
            ));
          },
        );
      },
    );
  }
}


