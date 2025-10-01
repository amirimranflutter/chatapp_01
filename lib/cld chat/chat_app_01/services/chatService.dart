

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = Uuid();

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _chatRooms = [];
  List<Map<String, dynamic>> _messages = [];
  String? _currentChatId;

  List<Map<String, dynamic>> get contacts => _contacts;
  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  List<Map<String, dynamic>> get messages => _messages;
  String? get currentChatId => _currentChatId;

  void setCurrentChat(String chatId) {
    _currentChatId = chatId;
    _loadMessages(chatId);
  }

  Future<List<Map<String, dynamic>>> loadContacts() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];
    try {
      final response = await _supabase
          .from('contacts')
          .select('id, contact_id, profile:profiles!inner(id,display_name, avatar_url, email)')
          .eq('user_id', currentUserId);
      // print("response --->>>$response");
      _contacts = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
      return _contacts;
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }




  Future<void> loadChatRooms() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final response = await _supabase
        .from('chat_participants')
        .select('''
          chat_rooms (
            id, name, type, created_at, created_by,
            profiles!chat_rooms_created_by_fkey (display_name)
          )
        ''')
        .eq('user_id', currentUserId);
    _chatRooms = response
        .map<Map<String, dynamic>>((item) => item['chat_rooms'] as Map<String, dynamic>)
        .toList();
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
    if (_currentChatId == null) return 'No chat selected';

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

  Future<String?> createChatRoom(String name, List<String> participantIds) async {
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
      final participants = participantIds.map((id) => {
        'chat_id': chatId,
        'user_id': id,
        'joined_at': DateTime.now().toIso8601String(),
      }).toList();

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

      loadContacts();
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
      final receiverId = participants
          .firstWhere((p) => p['user_id'] != currentUserId)['user_id'];

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
}
