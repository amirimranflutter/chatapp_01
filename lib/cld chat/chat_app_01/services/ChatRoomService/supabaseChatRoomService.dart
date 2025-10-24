import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatRoomService {
  final supabase = Supabase.instance.client;

  // Find existing private room between two users
  Future<Map<String, dynamic>?> findPrivateRoom(String userAId, String userBId) async {
    try {
      // Get all private rooms for userA
      final userARooms = await supabase
          .from('chat_room_participants')
          .select('chat_room_id, chat_rooms!inner(id, name, type, created_at)')
          .eq('user_id', userAId)
          .eq('chat_rooms.type', 'private');

      if (userARooms.isEmpty) return null;

      // Check each room to see if userB is also a participant
      for (var room in userARooms) {
        final chatRoomId = room['chat_room_id'];

        final userBParticipant = await supabase
            .from('chat_room_participants')
            .select('user_id')
            .eq('chat_room_id', chatRoomId)
            .eq('user_id', userBId)
            .maybeSingle();

        if (userBParticipant != null) {
          // Found existing room with both users
          return room['chat_rooms'];
        }
      }

      return null;
    } catch (e) {
      print('Error finding private room: $e');
      return null;
    }
  }

  // Create new private room with both users as participants
  Future<Map<String, dynamic>> createPrivateRoom(String userAId, String userBId) async {
    try {
      // 1. Create the chat room
      final newRoom = await supabase
          .from('chat_rooms')
          .insert({'type': 'private'})
          .select()
          .single();

      final chatRoomId = newRoom['id'];

      // 2. Add both users as participants using UPSERT to prevent duplicates
      await supabase
          .from('chat_room_participants')
          .upsert([
        {'chat_room_id': chatRoomId, 'user_id': userAId},
        {'chat_room_id': chatRoomId, 'user_id': userBId},
      ],
          onConflict: 'chat_room_id,user_id',
          ignoreDuplicates: true);

      return newRoom;
    } catch (e) {
      print('Error creating private room: $e');
      rethrow;
    }
  }
}
