// services/chatRoomServices/chatRoomSyncService.dart

import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/localChatRoomService.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/ChatRoomService/supabaseChatRoomService.dart';

class ChatRoomSyncService {
  final HiveChatRoomService _local;
  final SupabaseChatRoomService _remote;

  ChatRoomSyncService(this._local, this._remote);

  /// Sync chat rooms bidirectionally (pull from server, push local changes)
  Future<void> fullSync(String currentUserId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      print("⛔ No internet — skipping full sync");
      return;
    }

    try {
      print('🔄 Starting full chat room sync for user: $currentUserId');

      // Pull remote chat rooms first
      await syncFromSupabase(currentUserId);

      // Push any local-only rooms to Supabase
      await syncToSupabase(currentUserId);

      print('✅ Full chat room sync completed');
    } catch (e) {
      print('❌ Error during full sync: $e');
    }
  }

  /// Pull chat rooms from Supabase and save to local storage
  Future<void> syncFromSupabase(String currentUserId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      print("⛔ No internet — skipping pull from Supabase");
      return;
    }

    try {
      print('⬇️ Pulling chat rooms from Supabase...');

      // Fetch all chat rooms for user from Supabase
      final remoteChatRooms = await _remote.fetchChatRoomsForUser(currentUserId);

      if (remoteChatRooms.isEmpty) {
        print('📭 No chat rooms found on server');
        return;
      }

      // Save each room to local storage
      for (final room in remoteChatRooms) {
        await _local.saveChatRoom(room);
        print('💾 Saved chat room to Hive: ${room.id}');
      }

      print('✅ Pulled ${remoteChatRooms.length} chat rooms from Supabase');
    } catch (e) {
      print('❌ Error pulling from Supabase: $e');
    }
  }

  /// Push local chat rooms to Supabase if they don't exist remotely
  Future<void> syncToSupabase(String currentUserId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      print("⛔ No internet — skipping push to Supabase");
      return;
    }

    try {
      print('⬆️ Pushing local chat rooms to Supabase...');

      final localRooms = await _local.fetchChatRoomsForUser(currentUserId);

      if (localRooms.isEmpty) {
        print('📭 No local chat rooms to sync');
        return;
      }

      int uploadedCount = 0;

      for (final localRoom in localRooms) {
        // Check if room already exists on server
        final exists = await _remote.chatRoomExists(localRoom.id);

        if (!exists) {
          // Create room on Supabase
          await _uploadChatRoomToSupabase(localRoom);
          uploadedCount++;
        } else {
          print('⏭️ Chat room already exists on server: ${localRoom.id}');
        }
      }

      print('✅ Pushed $uploadedCount chat rooms to Supabase');
    } catch (e) {
      print('❌ Error pushing to Supabase: $e');
    }
  }

  /// Upload a single chat room to Supabase
  Future<void> _uploadChatRoomToSupabase(ChatRoom room) async {
    try {
      // Use the create method instead of insert to handle proper data format
      final response = await _remote.client.from('chat_rooms').insert({
        'id': room.id,
        'participant1_id': room.participant1Id,
        'participant2_id': room.participant2Id,
        'created_at': room.createdAt.toIso8601String(),
        'updated_at': room.updatedAt.toIso8601String(),
        'last_message_content': room.lastMessageContent,
        'last_message_at': room.lastMessageAt?.toIso8601String(),
      }).select().maybeSingle();

      if (response != null) {
        print('✅ Uploaded chat room to Supabase: ${room.id}');
      } else {
        print('⚠️ Failed to upload chat room: ${room.id}');
      }
    } catch (e) {
      print('❌ Error uploading chat room ${room.id}: $e');
    }
  }

  /// Find or create a chat room (checks both local and remote)
  Future<String> findOrCreateChatRoom(String user1Id, String user2Id) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (hasNetwork) {
      try {
        // Try Supabase first (authoritative source)
        print('🌐 Finding/creating chat room on Supabase...');
        final chatId = await _remote.findOrCreateChatRoom(user1Id, user2Id);

        // Sync this room to local storage
        final room = await _remote.getChatRoomById(chatId);
        if (room != null) {
          await _local.saveChatRoom(room);
          print('💾 Synced chat room to local storage: $chatId');
        }

        return chatId;
      } catch (e) {
        print('⚠️ Supabase failed, falling back to local: $e');
      }
    }

    // Fallback to local-only (offline mode)
    print('📱 Creating chat room locally (offline mode)');
    final chatId = await _local.findOrCreateChatRoom(user1Id, user2Id);

    // Mark for later sync
    _markForSync(chatId);

    return chatId;
  }

  /// Update last message in both local and remote
  Future<void> updateLastMessage(
      String chatId,
      String message,
      DateTime timestamp
      ) async {
    // Always update local immediately
    await _local.updateLastMessage(chatId, message, timestamp);
    print('💾 Updated last message locally for room: $chatId');

    // Try to update remote if online
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (hasNetwork) {
      try {
        await _remote.updateLastMessage(chatId, message, timestamp);
        print('☁️ Updated last message on Supabase for room: $chatId');
      } catch (e) {
        print('⚠️ Failed to update last message on server: $e');
        // Local update already succeeded, so this is OK
      }
    }
  }

  /// Sync a specific chat room by ID
  Future<void> syncChatRoom(String chatId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      print("⛔ No internet — can't sync chat room $chatId");
      return;
    }

    try {
      // Get from Supabase
      final remoteRoom = await _remote.getChatRoomById(chatId);

      if (remoteRoom != null) {
        // Save to local
        await _local.saveChatRoom(remoteRoom);
        print('✅ Synced chat room $chatId from server to local');
      } else {
        // Room exists locally but not remotely - upload it
        final localRoom = await _local.getChatRoomById(chatId);
        if (localRoom != null) {
          await _uploadChatRoomToSupabase(localRoom);
          print('✅ Uploaded local chat room $chatId to server');
        }
      }
    } catch (e) {
      print('❌ Error syncing chat room $chatId: $e');
    }
  }

  /// Mark a chat room for later sync (when created offline)
  void _markForSync(String chatId) {
    // You can implement this with a separate Hive box or shared preferences
    // to track which rooms need to be synced when network is available
    print('📌 Marked chat room for sync: $chatId');
    // TODO: Store in a "pending_sync" list
  }

  /// Sync all pending chat rooms (called when network becomes available)
  Future<void> syncPendingChatRooms() async {
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      print("⛔ No internet — can't sync pending chat rooms");
      return;
    }

    try {
      // TODO: Get list of pending chat room IDs
      final pendingIds = <String>[]; // Get from your pending sync storage

      print('🔄 Syncing ${pendingIds.length} pending chat rooms...');

      for (final chatId in pendingIds) {
        final localRoom = await _local.getChatRoomById(chatId);
        if (localRoom != null) {
          await _uploadChatRoomToSupabase(localRoom);
        }
      }

      print('✅ Synced all pending chat rooms');
      // TODO: Clear pending sync list
    } catch (e) {
      print('❌ Error syncing pending chat rooms: $e');
    }
  }

  /// Delete a chat room from both local and remote
  Future<void> deleteChatRoom(String chatId) async {
    // Delete locally
    await _local.deleteChatRoom(chatId);
    print('🗑️ Deleted chat room locally: $chatId');

    // Try to delete from remote if online
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (hasNetwork) {
      try {
        await _remote.deleteChatRoom(chatId);
        print('☁️ Deleted chat room from Supabase: $chatId');
      } catch (e) {
        print('⚠️ Failed to delete from server: $e');
      }
    }
  }

  /// Get local chat room count
  Future<int> getLocalChatRoomCount() async {
    return await _local.getChatRoomCount();
  }

  /// Clear all local chat rooms (for testing/logout)
  Future<void> clearLocalChatRooms() async {
    await _local.clearAllChatRooms();
    print('🧹 Cleared all local chat rooms');
  }

  /// Debug: Print sync status
  Future<void> printSyncStatus(String userId) async {
    final localCount = await _local.getChatRoomCount();
    final hasNetwork = await GlobalSyncManager.checkInternet();

    print('📊 Chat Room Sync Status:');
    print('   Local rooms: $localCount');
    print('   Network: ${hasNetwork ? "✅ Online" : "⛔ Offline"}');

    if (hasNetwork) {
      try {
        final remoteRooms = await _remote.fetchChatRoomsForUser(userId);
        print('   Remote rooms: ${remoteRooms.length}');
      } catch (e) {
        print('   Remote rooms: ❌ Error fetching');
      }
    }
  }
}
