// screens/chat_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/contactModel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Providers/chatProvider.dart';
import '../models/messageModel.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final ContactModel contact;

  const ChatScreen({
    required this.contact,
    required this.chatId,
    Key? key
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
// screens/chatScreen.dart

  @override
  void initState() {
    super.initState();

    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadMessages(widget.chatId);

      // Mark messages as read after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          chatProvider.markMessagesAsRead(widget.chatId);
        }
      });

      _scrollToBottom();
    });
  }


  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp background color
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg logo/chatlogo.jpg'), // Optional: Add WhatsApp-style background
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Column(
          children: [
            /// MESSAGE LIST
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMine = msg.senderId == chatProvider.currentUserId;
                  final showDateHeader = _shouldShowDateHeader(messages, index);

                  return Column(
                    children: [
                      if (showDateHeader) _buildDateHeader(msg.createdAt),
                      _buildMessageBubble(msg, isMine),
                    ],
                  );
                },
              ),
            ),

            /// INPUT FIELD
            _buildInputArea(chatProvider),
          ],
        ),
      ),
    );
  }

  // Build modern AppBar with avatar and online status
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF128C7E), // WhatsApp green
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: InkWell(
        onTap: () {
          // Navigate to contact profile
        },
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.contact.contactId}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: widget.contact.avatarUrl != null &&
                    widget.contact.avatarUrl!.isNotEmpty
                    ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.contact.avatarUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
                    : const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name ?? 'Chat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'online', // You can make this dynamic based on presence
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () {
            // Video call functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: () {
            // Voice call functionality
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view_contact', child: Text('View contact')),
            const PopupMenuItem(value: 'media', child: Text('Media, links, and docs')),
            const PopupMenuItem(value: 'search', child: Text('Search')),
            const PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
            const PopupMenuItem(value: 'wallpaper', child: Text('Wallpaper')),
            const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
          ],
        ),
      ],
    );
  }

  // Build message bubble with status indicators
  Widget _buildMessageBubble(Message msg, bool isMine) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show contact avatar for received messages
          if (!isMine && widget.contact.avatarUrl != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.contact.avatarUrl!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Icon(Icons.person, size: 16),
                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 16),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFFDCF8C6) // Light green for sent messages
                    : Colors.white, // White for received messages
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMine ? 12 : 0),
                  bottomRight: Radius.circular(isMine ? 0 : 12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message content
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      msg.content,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Time and status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatusIcon(msg.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Empty space for sent messages alignment
          if (isMine && widget.contact.avatarUrl != null)
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  // Build status icon (sent, delivered, read)
  Widget _buildMessageStatusIcon(MessageStatus status) {
    IconData iconData;
    Color color;

    switch (status) {
      case MessageStatus.sent:
        iconData = Icons.done;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        color = const Color(0xFF34B7F1); // Blue for read
        break;
    }

    return Icon(iconData, size: 16, color: color);
  }

  // Build date header
  Widget _buildDateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Build input area
  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji/Attachment button
            IconButton(
              icon: Icon(Icons.add, color: Colors.grey[700]),
              onPressed: () {
                // Show attachment options
                _showAttachmentOptions();
              },
            ),

            // Text input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: "Type a message",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          setState(() {});
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[700]),
                      onPressed: () {
                        // Show emoji picker
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Send or voice message button
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF128C7E),
              child: IconButton(
                icon: Icon(
                  _textController.text.trim().isEmpty
                      ? Icons.mic
                      : Icons.send,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () async {
                  if (_textController.text.trim().isEmpty) {
                    // Record voice message
                  } else {
                    await _sendMessage(chatProvider);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Send message function
  Future<void> _sendMessage(ChatProvider chatProvider) async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      await chatProvider.sendMessage(text, widget.chatId);
      _scrollToBottom();
    }
  }

  // Show attachment options
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.photo, 'Gallery', Colors.purple),
                _buildAttachmentOption(Icons.camera_alt, 'Camera', Colors.pink),
                _buildAttachmentOption(Icons.insert_drive_file, 'Document', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Helper: Check if date header should be shown
  bool _shouldShowDateHeader(List<Message> messages, int index) {
    if (index == 0) return true;

    final currentDate = messages[index].createdAt;
    final previousDate = messages[index - 1].createdAt;

    return !_isSameDay(currentDate, previousDate);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Format time (e.g., "2:30 PM")
  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  // Format date (e.g., "Today", "Yesterday", "Jan 15")
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();

    if (_isSameDay(localDate, now)) {
      return 'Today';
    } else if (_isSameDay(localDate, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, y').format(localDate);
    }
  }
}
