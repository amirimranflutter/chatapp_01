import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/MainScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth/authService.dart';
import '../services/chatService.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic>? _receiverProfile;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _loadReceiverProfile();
    });
  }

  @override
  // In ChatService
  Future<void> _loadReceiverProfile() async {
    final chatService = Provider.of<ChatService>(context, listen: false);

    if (chatService.currentChatId != null) {
      try {
        final profile = await chatService.getReceiverProfile(
          chatService.currentChatId!,
        );

        setState(() {
          _receiverProfile = profile;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Error loading profile: $e');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
      return Scaffold(
        appBar: AppBar(

          // 👈 Increase this if needed
          leadingWidth: 120,
          leading: IconButton(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back),
                if (_receiverProfile != null)
                  Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: _receiverProfile!['avatar_url'] != null
                          ? NetworkImage(_receiverProfile!['avatar_url'])
                          : null,
                      child: _receiverProfile!['avatar_url'] == null
                          ? Text(
                        _receiverProfile!['display_name'][0].toUpperCase(),
                        style: TextStyle(fontSize: 12),
                      )
                          : null,
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          title: Text(_receiverProfile?['display_name'] ?? 'Chat'),

          actions: [
            if (_receiverProfile != null)
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {
                  // Options (e.g., view profile)
                },
              ),
          ],
          elevation: 0,
        ),

        body: Consumer2<ChatService, AuthService>(
          builder: (context, chatService, authService, _) {
            // Scroll to bottom when new messages arrive
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            return Column(
              children: [
                // Messages List
                Expanded(
                  child: chatService.messages.isEmpty
                      ? Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatService.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatService.messages[index];
                      final isMe =
                          message['sender_id'] ==
                              authService.currentUser?.id;
                      final profile = message['profiles'];

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue[200],
                                child: Text(
                                  profile['display_name'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue[600]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: isMe
                                        ? Radius.circular(16)
                                        : Radius.circular(4),
                                    bottomRight: isMe
                                        ? Radius.circular(4)
                                        : Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          profile['display_name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    Text(
                                      message['content'],
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm').format(
                                        DateTime.parse(
                                          message['created_at'],
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue[700],
                                child: Text(
                                  'Y',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Message Input Area
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                            tooltip: 'Send message',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    final content = _messageController.text.trim();
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollToBottom();
    });

    final error = await chatService.sendMessage(content);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }
}
