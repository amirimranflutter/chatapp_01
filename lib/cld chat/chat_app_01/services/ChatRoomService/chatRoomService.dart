import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/supabaseChatRoomService.dart';

class ChatRoomService {
  // Returns an existing chat room id between users, or creates new and returns the id.
  Future<String> findOrCreateChatRoom(String userAId, String userBId) async {
    // 1. Try find chat room in Supabase (remote)
    final existingRoom = await SupabaseChatRoomService().findPrivateRoom(userAId, userBId);
    if (existingRoom != null) return existingRoom['id'];

    // 2. If not found, create new room in Supabase
    final newRoom = await SupabaseChatRoomService().createPrivateRoom(userAId, userBId);
    return newRoom['id'];
  }

}


