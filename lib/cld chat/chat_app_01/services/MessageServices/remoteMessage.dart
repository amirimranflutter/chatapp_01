// services/remote/supabase_message_service.dart

import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMessageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Upload message to Supabase
  Future<void> uploadMessage(MessageModel message) async {
    await _client.from('messages').insert(message.toJson());
  }

  /// Fetch recent messages between two users
  Future<List<MessageModel>> fetchMessages(
      String userId, String contactId) async {
    final response = await _client
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at');

    return response.map((json) => MessageModel.fromJson(json)).toList();
  }

  final supabase = Supabase.instance.client;


// Future<DateTime?> getLastMessageTime(String chatRoomId) async {
// final response = await supabase
//     .from('messages')
//     .select('created_at')
//     .eq('chat_room_id', chatRoomId)
//     .order('created_at', ascending: false)
//     .limit(1)
//     .maybeSingle();
//
// if (response == null) return null;
// return DateTime.parse(response['created_at']);
// }
  }

