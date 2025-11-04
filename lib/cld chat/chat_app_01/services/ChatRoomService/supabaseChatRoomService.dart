import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';

class SupabaseChatRoomService {
  final SupabaseClient _client = Supabase.instance.client;

  // Upload local chat room to Supabase (returns Supabase ID on success)
  Future<String?> uploadChatRoom(ChatRoomModel room) async {
    final response = await _client.from('chat_rooms').insert({
      'id': room.id,
      'name': room.name,
      'type': room.type,
      'created_at': room.createdAt.toUtc().toIso8601String(),
    }).select('id').maybeSingle();

    if (response == null || response['id'] == null) {
      print('❌ Failed to upload room: $room');
      return null;
    }
    print('✅ Synced chat room to Supabase: ID=${response['id']}');
    return response['id'] as String;
  }

  // Fetch all Supabase chat rooms for a user (by participant)
  Future<List<Map<String, dynamic>>> fetchChatRoomsForUser(String userId) async {
    final response = await _client
        .rpc('get_user_chat_rooms', params: {'uid': userId}); // assumes you have this RPC or a view
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Check if a chat room exists in remote (by ID)
  Future<bool> chatRoomExists(String id) async {
    final response = await _client.from('chat_rooms').select('id').eq('id', id).maybeSingle();
    return response != null;
  }
}
