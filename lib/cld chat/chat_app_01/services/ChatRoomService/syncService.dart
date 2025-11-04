import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/localChatRoomService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/supabaseChatRoomService.dart';

class ChatRoomSyncService {
  final HiveChatRoomService _local;
  final SupabaseChatRoomService _remote;

  ChatRoomSyncService(this._local, this._remote);

  // Sync all local chat rooms to Supabase if not there yet
  Future<void> syncChatRoomsToSupabase(String currentUserId) async {
    final hasNetwork=await GlobalSyncManager.checkInternet();
    if(hasNetwork) {
      print("⛔ No internet — skipping sync");
      return;
    }
    final localRooms = await _local.fetchChatRoomsForUser(currentUserId);

    for (final localRoom in localRooms) {
      final exists = await _remote.chatRoomExists(localRoom.id);
      if (!exists) {
        await _remote.uploadChatRoom(localRoom);
      }
    }
    print('✅ Chat rooms synced.');
  }
}
