// screens/chat_screen.dart

import 'package:chat_app_cld/cld%20chat/chat_app_01/services/MessageServices/localMessage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/chatProvider.dart';
import '../models/contactModel.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
final String chatId;
  const ChatScreen({required this.contactName,required this.chatId, Key? key}) : super(key: key);

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
        title: Text(widget.contactName ?? 'Chat'),
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
