// screens/chat_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/contactModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/chatProvider.dart';

class ChatScreen extends StatefulWidget {
final String chatId;
final ContactModel contact;
  const ChatScreen({required this.contact, required this.chatId,Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    /// Load messages for this user-contact pair
    // Future.microtask(() {
    //   context.read<ChatProvider>().loadMessages(widget.contactName);
    //   print('contact->>>>> in chat screen---->>> ${widget.contactName}');
    // });
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadMessages(widget.chatId);

  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
      children: [
      // Circular avatar with CachedNetworkImage
      CircleAvatar(
      radius: 20,
        backgroundColor: Colors.grey[300],
        child: widget.contact.avatarUrl != null && widget.contact.avatarUrl!.isNotEmpty
            ? ClipOval(
          child: CachedNetworkImage(
            imageUrl: widget.contact.avatarUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircularProgressIndicator(
              strokeWidth: 2,
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
        )
            : Icon(Icons.person, color: Colors.white),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          widget.contact.name ?? 'Chat',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ],
    ),
      ),
      body: Column(
        children: [
          /// MESSAGE LIST
          Expanded(
            child: ListView.builder(
              reverse: false, // bottom is last message
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                final isMine =
                    msg.senderId == chatProvider.currentUserId;

                return Align(
                  alignment:
                  isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.content),
                        const SizedBox(height: 3),
                        Text(
                          msg.createdAt.toLocal().toString().split('.')[0],
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// INPUT FIELD
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration:
                      const InputDecoration(hintText: "Type a message..."),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        await chatProvider.sendMessage(
            text, widget.chatId);
        _textController.clear();
    }
    // HiveMessageService().printAllMessages();
    // HiveMessageService().clearAllMessages();

                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
