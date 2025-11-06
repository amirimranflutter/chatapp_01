
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chatRoomModel.dart';

class SupabaseChatRoomService {
   final SupabaseClient client = Supabase.instance.client;

  /// Find or create chat room using the database function
  Future<String> findOrCreateChatRoom(String user1Id, String user2Id) async {
    try {
      print('🔄 Calling Supabase find_or_create_chat_room...');

      final response = await client.rpc(
        'find_or_create_chat_room',
        params: {
          'user1_id': user1Id,
          'user2_id': user2Id,
        },
      );

      final chatRoomId = response as String;
      print('✅ Got chat room ID from Supabase: $chatRoomId');
      return chatRoomId;
    } catch (e) {
      print('❌ Error calling find_or_create_chat_room: $e');
      rethrow;
    }
  }

  /// Fetch all chat rooms for a user
  Future<List<ChatRoom>> fetchChatRoomsForUser(String userId) async {
    try {
      final response = await client
          .from('chat_rooms')
          .select()
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('updated_at', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((json) => ChatRoom.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching chat rooms: $e');
      return [];
    }
  }

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoomById(String chatId) async {
    try {
      final response = await client
          .from('chat_rooms')
          .select()
          .eq('id', chatId)
          .maybeSingle();

      if (response == null) return null;

      return ChatRoom.fromJson(response);
    } catch (e) {
      print('❌ Error fetching chat room: $e');
      return null;
    }
  }

  /// Update chat room's last message (called after sending message)
  Future<void> updateLastMessage(
      String chatId,
      String message,
      DateTime timestamp
      ) async {
    try {
      await client.from('chat_rooms').update({
        'last_message_content': message,
        'last_message_at': timestamp.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      print('✅ Updated last message for room: $chatId');
    } catch (e) {
      print('❌ Error updating last message: $e');
    }
  }

  /// Check if chat room exists
  Future<bool> chatRoomExists(String chatId) async {
    try {
      final response = await client
          .from('chat_rooms')
          .select('id')
          .eq('id', chatId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error checking chat room existence: $e');
      return false;
    }
  }

  /// Create chat room manually (if not using the function)
  Future<String?> createChatRoom(String user1Id, String user2Id) async {
    try {
      // Sort IDs to ensure consistency
      final smallerId = user1Id.compareTo(user2Id) < 0 ? user1Id : user2Id;
      final largerId = user1Id.compareTo(user2Id) < 0 ? user2Id : user1Id;

      final response = await client.from('chat_rooms').insert({
        'participant1_id': smallerId,
        'participant2_id': largerId,
      }).select('id').single();

      final chatRoomId = response['id'] as String;
      print('✅ Created new chat room: $chatRoomId');
      return chatRoomId;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      return null;
    }
  }

  /// Delete chat room
  Future<void> deleteChatRoom(String chatId) async {
    try {
      await client.from('chat_rooms').delete().eq('id', chatId);
      print('🗑️ Deleted chat room: $chatId');
    } catch (e) {
      print('❌ Error deleting chat room: $e');
    }
  }

  /// Get chat room with contact details (join with users table)
  Future<Map<String, dynamic>?> getChatRoomWithContactInfo(
      String chatId,
      String currentUserId
      ) async {
    try {
      final response = await client
          .from('chat_rooms')
          .select('''
            *,
            participant1:participant1_id(id, name, email, avatar_url),
            participant2:participant2_id(id, name, email, avatar_url)
          ''')
          .eq('id', chatId)
          .maybeSingle();

      if (response == null) return null;

      // Determine which participant is the contact (not current user)
      final participant1 = response['participant1'];
      final participant2 = response['participant2'];

      final contact = participant1['id'] == currentUserId
          ? participant2
          : participant1;

      return {
        'chat_room': ChatRoom.fromJson(response),
        'contact': contact,
      };
    } catch (e) {
      print('❌ Error fetching chat room with contact: $e');
      return null;
    }
  }

  /// Subscribe to chat room updates (for real-time last message changes)
  RealtimeChannel subscribeToChatRoomUpdates(
      String userId,
      Function(ChatRoom) onUpdate,
      ) {
    return client
        .channel('chat_rooms:$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'chat_rooms',
      callback: (payload) {
        final updatedRoom = ChatRoom.fromJson(payload.newRecord);

        // Only notify if this user is a participant
        if (updatedRoom.participant1Id == userId ||
            updatedRoom.participant2Id == userId) {
          onUpdate(updatedRoom);
        }
      },
    )
        .subscribe();
  }
}
