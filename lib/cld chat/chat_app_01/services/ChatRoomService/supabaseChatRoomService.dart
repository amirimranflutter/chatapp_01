import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatRoomService {
  /// Find existing private chat room between two users
  final supabase=Supabase.instance.client;
  Future<Map<String, dynamic>?> findPrivateRoom(String userAId, String userBId) async {
    try {
      final response = await supabase
          .from('chat_rooms')
          .select()
          .eq('type', 'private')
          .or('participants @> ARRAY[$userAId,$userBId]')
          .single();

      return response; // ✅ already a Map<String, dynamic>
    } catch (e) {
      // No record found or query failed
      return null;
    }
  }



  /// Create a new private chat room
  Future<Map<String, dynamic>> createPrivateRoom(String userAId, String userBId) async {
    final response = await supabase
        .from('chat_rooms')
        .insert({
      'type': 'private',
      'name': null, // for group only
    })
        .select('id')
        .single(); // returns Map<String, dynamic>

    final chatId = response['id']; // ✅ no `.data`

    // Insert chat participants
    await supabase.from('chat_room_participants').insert([
      {'chat_room_id': chatId, 'user_id': userAId},
      {'chat_room_id': chatId, 'user_id': userBId},
    ]);

    return {'id': chatId};
  }

}
