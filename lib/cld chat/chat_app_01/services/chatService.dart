import 'package:chat_app_cld/cld%20chat/chat_app_01/services/contactService.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = Uuid();


  List<Map<String, dynamic>> _chatRooms = [];
  List<Map<String, dynamic>> _messages = [];
  String? _currentChatId;
  final ContactService contactService=ContactService();



  List<Map<String, dynamic>> get chatRooms => _chatRooms;

  List<Map<String, dynamic>> get messages => _messages;

  String? get currentChatId => _currentChatId;


  void setCurrentChat(String chatId) {
    _currentChatId = chatId;
    _loadMessages(chatId);
  }



  Future<void> loadChatRooms() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final response = await _supabase
        .from('chat_participants')
        .select('''
        chat_rooms (
          id,
          name,
          type,
          created_at,
          participants:chat_participants (
            user_id,
            profiles(display_name, avatar_url)
          ),
          messages(content, created_at)
        )
      ''')
        .eq('user_id', currentUserId);


    _chatRooms = [];

    for (var item in response) {
      final room = item['chat_rooms'];
      final participants = room['participants'] as List;
      final others = participants
          .where((p) => p['user_id'] != currentUserId)
          .toList();

      final otherUser = others.isNotEmpty
          ? others.first['profiles']['display_name']
          : 'Unknown';

      final messages = room['messages'] as List?;
      final lastMessage = (messages != null && messages.isNotEmpty)
          ? messages.last['content']
          : 'No messages yet';

      _chatRooms.add({
        'id': room['id'],
        'type': room['type'],
        'name': room['name'],
        'created_at': room['created_at'],
        'otherUser': otherUser,
        'lastMessage': lastMessage,
      });
    }

    notifyListeners();
  }


  Future<void> _loadMessages(String chatId) async {
    final response = await _supabase
        .from('messages')
        .select('''
          id, content, created_at, sender_id,
          profiles!messages_sender_id_fkey (display_name, avatar_url)
        ''')
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    _messages = response;
    notifyListeners();

    // Listen for real-time updates
    _supabase
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            _handleNewMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  void _handleNewMessage(Map<String, dynamic> newMessage) async {
    // Fetch complete message data with profile info
    final completeMessage = await _supabase
        .from('messages')
        .select('''
          id, content, created_at, sender_id,
          profiles!messages_sender_id_fkey (display_name, avatar_url)
        ''')
        .eq('id', newMessage['id'])
        .single();

    _messages.add(completeMessage);
    notifyListeners();
  }

  Future<String?> sendMessage(String content) async {
    if (_currentChatId == null || _currentChatId!.isEmpty) {
      return 'No chat selected';
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 'Not authenticated';

    try {
      await _supabase.from('messages').insert({
        'id': _uuid.v4(),
        'chat_id': _currentChatId,
        'sender_id': currentUserId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createChatRoom(
    String name,
    List<String> participantIds,
  ) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 'Not authenticated';

    try {
      final chatId = _uuid.v4();

      // Create chat room
      await _supabase.from('chat_rooms').insert({
        'id': chatId,
        'name': name,
        'type': 'group',
        'created_by': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Add participants
      final participants = participantIds
          .map(
            (id) => {
              'chat_id': chatId,
              'user_id': id,
              'joined_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      // Add creator as participant
      participants.add({
        'chat_id': chatId,
        'user_id': currentUserId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      await _supabase.from('chat_participants').insert(participants);

      loadChatRooms();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addContact(String email) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 'Not authenticated';

    try {
      // Find user by email
      final userResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .single();

      final contactId = userResponse['id'];

      // Add contact
      await _supabase.from('contacts').insert({
        'user_id': currentUserId,
        'contact_id': contactId,
        'created_at': DateTime.now().toIso8601String(),
      });

      contactService.loadContacts();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createDirectChat(String contactId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 'Not authenticated';

    try {
      // Check if direct chat already exists
      final existingChat = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', currentUserId);

      for (var chat in existingChat) {
        final otherParticipants = await _supabase
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chat['chat_id'])
            .neq('user_id', currentUserId);

        if (otherParticipants.length == 1 &&
            otherParticipants.first['user_id'] == contactId) {
          setCurrentChat(chat['chat_id']);
          return null;
        }
      }

      // Create new direct chat
      final chatId = _uuid.v4();

      await _supabase.from('chat_rooms').insert({
        'id': chatId,
        'name': null,
        'type': 'direct',
        'created_by': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _supabase.from('chat_participants').insert([
        {
          'chat_id': chatId,
          'user_id': currentUserId,
          'joined_at': DateTime.now().toIso8601String(),
        },
        {
          'chat_id': chatId,
          'user_id': contactId,
          'joined_at': DateTime.now().toIso8601String(),
        },
      ]);

      loadChatRooms();
      setCurrentChat(chatId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getReceiverProfile(String chatId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    try {
      // Get all participants in the chat
      final participants = await _supabase
          .from('chat_participants')
          .select('user_id')
          .eq('chat_id', chatId);

      // Find the receiver (not the current user)
      final receiverId = participants.firstWhere(
        (p) => p['user_id'] != currentUserId,
      )['user_id'];

      // Get the receiver's profile
      final profile = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url')
          .eq('id', receiverId)
          .single();

      return profile;
    } catch (e) {
      print('Error fetching receiver profile: $e');
      return null;
    }
  }
  Future<String?> deleteChatRoom(String chatId) async {
    try {
      // 1. Delete messages first (if you don’t have cascading delete in DB)
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);

      // 2. Delete participants
      await _supabase
          .from('chat_participants')
          .delete()
          .eq('chat_id', chatId);

      // 3. Delete the chat room
      await _supabase
          .from('chat_rooms')
          .delete()
          .eq('id', chatId);

      // 4. Update UI
      _chatRooms.removeWhere((room) => room['id'] == chatId);
      _messages.clear();
      _currentChatId = null;

      notifyListeners();
      return null; // success
    } catch (e) {
      return e.toString(); // return error
    }
  }



}
