// screens/chatContactListScreen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Providers/chatProvider.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Screens/chatScreen.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/DateUtils.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/contactModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/localChatRoomService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/supabaseChatRoomService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService/lookprofile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/ChatRoomService/syncService.dart';
import '../services/MessageServices/messageRepository.dart';

class ChatContactListScreen extends StatefulWidget {
  const ChatContactListScreen({Key? key}) : super(key: key);

  @override
  _ChatContactListScreenState createState() => _ChatContactListScreenState();
}

class _ChatContactListScreenState extends State<ChatContactListScreen> {
  final _supabase = Supabase.instance.client;
  List<ChatRoomWithContact> _chatRooms = [];
  bool _isLoading = true;
  String? _error;

  // Services
  late final ChatRoomSyncService _chatRoomSyncService;
  late final SyncMessageService _messageSyncService;

  // Real-time subscription
  RealtimeChannel? _chatRoomSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _chatRoomSyncService = ChatRoomSyncService(
      HiveChatRoomService(),
      SupabaseChatRoomService(),
    );

    _messageSyncService = context.read<ChatProvider>().messageSyncService;

    _loadChats();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _unsubscribeFromUpdates();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUserId = ProfileLookupService.currentUser!.id;

      // Sync chat rooms from server
      await _chatRoomSyncService.syncFromSupabase(currentUserId);

      // Fetch chat rooms with contact information
      final chatRooms = await _fetchChatRoomsWithContacts(currentUserId);

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading chats: $e');
    }
  }

  Future<List<ChatRoomWithContact>> _fetchChatRoomsWithContacts(String userId) async {
    try {
      // Fetch chat rooms from Supabase with user details
      final response = await _supabase
          .from('chat_rooms')
          .select('''
            *,
            participant1:participant1_id(id, name, email, avatar_url),
            participant2:participant2_id(id, name, email, avatar_url)
          ''')
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('updated_at', ascending: false);

      final List<ChatRoomWithContact> chatRoomsWithContacts = [];

      for (var roomData in response) {
        final chatRoom = ChatRoom.fromJson(roomData);

        // Determine which participant is the contact (not current user)
        final participant1 = roomData['participant1'];
        final participant2 = roomData['participant2'];

        final contactData = participant1['id'] == userId
            ? participant2
            : participant1;

        final contact = ContactModel(
          id: contactData['id'],
          name: contactData['name'] ?? 'Unknown',
          email: contactData['email'],
          avatarUrl:  contactData['avatar_url'],

        );

        // Get unread count
        final unreadCount = await _messageSyncService.getUnreadCount(
          chatRoom.id,
          userId,
        );

        chatRoomsWithContacts.add(ChatRoomWithContact(
          chatRoom: chatRoom,
          contact: contact,
          unreadCount: unreadCount,
        ));
      }

      return chatRoomsWithContacts;
    } catch (e) {
      print('❌ Error fetching chat rooms with contacts: $e');
      return [];
    }
  }

  void _subscribeToUpdates() {
    final currentUserId = ProfileLookupService.currentUser!.id;

    _chatRoomSubscription = _supabase
        .channel('chat_rooms:$currentUserId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chat_rooms',
      callback: (payload) {
        print('🔔 Chat room updated, refreshing list...');
        _loadChats(); // Refresh the list when any room updates
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_rooms',
      callback: (payload) {
        print('🔔 New chat room created, refreshing list...');
        _loadChats();
      },
    )
        .subscribe();
  }

  void _unsubscribeFromUpdates() {
    if (_chatRoomSubscription != null) {
      _supabase.removeChannel(_chatRoomSubscription!);
      _chatRoomSubscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF128C7E), // WhatsApp green
        elevation: 0.5,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new_group', child: Text('New group')),
              const PopupMenuItem(value: 'new_broadcast', child: Text('New broadcast')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        onPressed: () {
          // TODO: Navigate to contacts to start new chat
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF128C7E)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading chats',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF128C7E),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with your contacts',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _chatRooms.length,
      itemBuilder: (context, index) {
        final item = _chatRooms[index];
        return _buildChatListItem(item);
      },
    );
  }

  Widget _buildChatListItem(ChatRoomWithContact item) {
    final chatRoom = item.chatRoom;
    final contact = item.contact;
    final unreadCount = item.unreadCount;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatRoom.id,
              contact: contact,
            ),
          ),
        );

        // Refresh list after returning from chat (to update read status)
        _loadChats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Hero(
              tag: 'avatar_${contact.contactId}',
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[300],
                child: contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                    ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: contact.avatarUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                )
                    : const Icon(Icons.person, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 16),

            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          contact.name.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Timestamp
                      Text(
                        _formatTimestamp(chatRoom.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? const Color(0xFF25D366)
                              : Colors.grey[600],
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message and unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatRoom.lastMessageContent ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Unread badge
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today: show time
      return DateFormat('h:mm a').format(timestamp);
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      // This week: show day name
      return DateFormat('EEEE').format(timestamp);
    } else {
      // Older: show date
      return DateFormat('M/d/yy').format(timestamp);
    }
  }
}

// Helper class to hold chat room with contact info
class ChatRoomWithContact {
  final ChatRoom chatRoom;
  final ContactModel contact;
  final int unreadCount;

  ChatRoomWithContact({
    required this.chatRoom,
    required this.contact,
    required this.unreadCount,
  });
}
