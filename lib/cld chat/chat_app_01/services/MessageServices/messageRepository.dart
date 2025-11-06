// services/MessageServices/syncMessageService.dart

import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';
import 'package:chat_app_cld/cld%20chat/chat_app_01/services/MessageServices/remoteMessage.dart';

import 'localMessage.dart';

class SyncMessageService {
  final HiveMessageService _local;
  final SupabaseMessageService _remote;

  SyncMessageService(this._local, this._remote);

  /// Send a message: save locally first, then sync to remote
  Future<Message?> sendMessage(Message message) async {
    // Save locally immediately (optimistic update)
    await _local.saveMessage(message);
    print('💾 Message saved locally: ${message.id}');

    // Check network availability
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (hasNetwork) {
      try {
        // Send to Supabase
        final sentMessage = await _remote.sendMessage(message);

        if (sentMessage != null) {
          // Update with server version (has real ID and timestamp)
          await _local.updateMessage(sentMessage);
          await _local.markSynced(sentMessage.id);
          print('✅ Message synced to server: ${sentMessage.id}');
          return sentMessage;
        } else {
          print('⚠️ Server returned null, message remains local');
          return message;
        }
      } catch (e) {
        print('⚠️ Failed to sync message to server: $e');
        // Message remains in local storage with is_synced = false
        return message;
      }
    } else {
      print('⛔ No internet - message saved locally only');
      return message;
    }
  }

  /// Get messages from local storage (fast, offline-ready)
  Future<List<Message>> getLocalMessages(String chatId) async {
    return await _local.getMessagesByChatId(chatId);
  }

  /// Fetch messages from server and save to local
  Future<List<Message>> fetchAndSyncMessages(String chatId, {int limit = 50}) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (!hasNetwork) {
      print('⛔ No internet - returning local messages only');
      return await _local.getMessagesByChatId(chatId);
    }

    try {
      // Fetch from Supabase
      final remoteMessages = await _remote.fetchMessages(chatId, limit: limit);

      if (remoteMessages.isNotEmpty) {
        // Save all to local storage
        await _local.saveMessages(remoteMessages);
        print('✅ Synced ${remoteMessages.length} messages from server');
      }

      return remoteMessages;
    } catch (e) {
      print('⚠️ Failed to fetch from server: $e');
      // Fallback to local messages
      return await _local.getMessagesByChatId(chatId);
    }
  }

  /// Fetch paginated messages (for infinite scroll)
  Future<List<Message>> fetchMessagesWithPagination(
      String chatId, {
        required int limit,
        required int offset,
      }) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (!hasNetwork) {
      print('⛔ No internet - pagination not available');
      return [];
    }

    try {
      final messages = await _remote.fetchMessagesWithPagination(
        chatId,
        limit: limit,
        offset: offset,
      );

      // Save to local cache
      if (messages.isNotEmpty) {
        await _local.saveMessages(messages);
      }

      return messages;
    } catch (e) {
      print('⚠️ Failed to fetch paginated messages: $e');
      return [];
    }
  }

  /// Sync pending/unsynced messages to server (when internet returns)
  Future<void> syncPendingMessages() async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (!hasNetwork) {
      print('⛔ No internet - cannot sync pending messages');
      return;
    }

    try {
      final unsyncedMessages = await _local.getUnsyncedMessages();

      if (unsyncedMessages.isEmpty) {
        print('✅ No pending messages to sync');
        return;
      }

      print('🔄 Syncing ${unsyncedMessages.length} pending messages...');
      int successCount = 0;

      for (final message in unsyncedMessages) {
        try {
          final sentMessage = await _remote.sendMessage(message);

          if (sentMessage != null) {
            await _local.updateMessage(sentMessage);
            await _local.markSynced(sentMessage.id);
            successCount++;
            print('✅ Synced message ${message.id}');
          }
        } catch (e) {
          print('⚠️ Failed to sync message ${message.id}: $e');
          // Continue with next message
        }
      }

      print('✅ Successfully synced $successCount/${unsyncedMessages.length} messages');
    } catch (e) {
      print('❌ Error syncing pending messages: $e');
    }
  }

  /// Update message status (delivered, read)
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    // Update locally first
    await _local.updateMessageStatus(messageId, status);

    // Try to update on server
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (hasNetwork) {
      try {
        await _remote.updateMessageStatus(messageId, status);
        print('✅ Updated message status to ${status.name}: $messageId');
      } catch (e) {
        print('⚠️ Failed to update status on server: $e');
        // Local update already succeeded
      }
    }
  }

  /// Mark messages as delivered
  Future<void> markMessagesAsDelivered(String chatId, String receiverId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (hasNetwork) {
      try {
        await _remote.markMessagesAsDelivered(chatId, receiverId);

        // Update local copies
        final messages = await _local.getMessagesByChatId(chatId);
        for (var message in messages) {
          if (message.receiverId == receiverId &&
              message.status == MessageStatus.sent) {
            await _local.updateMessageStatus(message.id, MessageStatus.delivered);
          }
        }

        print('✅ Marked messages as delivered for chat: $chatId');
      } catch (e) {
        print('⚠️ Failed to mark messages as delivered: $e');
      }
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String receiverId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (hasNetwork) {
      try {
        await _remote.markMessagesAsRead(chatId, receiverId);

        // Update local copies
        final messages = await _local.getMessagesByChatId(chatId);
        for (var message in messages) {
          if (message.receiverId == receiverId &&
              message.status != MessageStatus.read) {
            await _local.updateMessageStatus(message.id, MessageStatus.read);
          }
        }

        print('✅ Marked messages as read for chat: $chatId');
      } catch (e) {
        print('⚠️ Failed to mark messages as read: $e');
      }
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    // Delete locally
    await _local.deleteMessage(messageId);

    // Try to delete on server
    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (hasNetwork) {
      try {
        await _remote.deleteMessage(messageId);
        print('🗑️ Deleted message on both local and server: $messageId');
      } catch (e) {
        print('⚠️ Failed to delete on server: $e');
      }
    }
  }

  /// Get the last message for a chat room
  Future<Message?> getLastMessage(String chatId) async {
    // Try local first (faster)
    final localLast = await _local.getLastMessageForChat(chatId);

    final hasNetwork = await GlobalSyncManager.checkInternet();
    if (!hasNetwork) {
      return localLast;
    }

    try {
      // Fetch latest messages to ensure we have the most recent
      final recentMessages = await _remote.fetchMessages(chatId, limit: 1);

      if (recentMessages.isNotEmpty) {
        final serverLast = recentMessages.first;
        await _local.saveMessage(serverLast);
        return serverLast;
      }

      return localLast;
    } catch (e) {
      print('⚠️ Failed to fetch last message from server: $e');
      return localLast;
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(String chatId, String currentUserId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (hasNetwork) {
      try {
        // Get accurate count from server
        return await _remote.getUnreadCount(chatId, currentUserId);
      } catch (e) {
        print('⚠️ Failed to get unread count from server: $e');
      }
    }

    // Fallback to local count
    return await _local.getUnreadCount(chatId, currentUserId);
  }

  /// Search messages
  Future<List<Message>> searchMessages(String chatId, String query) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (hasNetwork) {
      try {
        // Search on server (more powerful)
        final results = await _remote.searchMessages(chatId, query);

        // Cache results locally
        if (results.isNotEmpty) {
          await _local.saveMessages(results);
        }

        return results;
      } catch (e) {
        print('⚠️ Server search failed, falling back to local: $e');
      }
    }

    // Fallback to local search
    return await _local.searchMessages(chatId, query);
  }

  /// Get messages by type (images, files, etc.)
  Future<List<Message>> getMessagesByType(String chatId, MessageType type) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (hasNetwork) {
      try {
        return await _remote.getMessagesByType(chatId, type);
      } catch (e) {
        print('⚠️ Failed to fetch from server: $e');
      }
    }

    // Fallback to local
    return await _local.getMessagesByType(chatId, type);
  }

  /// Clear all messages for a chat (locally)
  Future<void> clearChatMessages(String chatId) async {
    await _local.clearChatMessages(chatId);
    print('🧹 Cleared local messages for chat: $chatId');
  }

  /// Get message count for a chat
  Future<int> getMessageCount(String chatId) async {
    return await _local.getMessageCount(chatId);
  }

  /// Full sync: pull from server and push pending
  Future<void> fullSync(String chatId) async {
    final hasNetwork = await GlobalSyncManager.checkInternet();

    if (!hasNetwork) {
      print('⛔ No internet - cannot perform full sync');
      return;
    }

    try {
      print('🔄 Starting full sync for chat: $chatId');

      // First, sync pending messages
      await syncPendingMessages();

      // Then, fetch latest from server
      await fetchAndSyncMessages(chatId);

      print('✅ Full sync completed for chat: $chatId');
    } catch (e) {
      print('❌ Full sync failed: $e');
    }
  }

  /// Debug: Print sync status
  Future<void> printSyncStatus(String chatId) async {
    final localMessages = await _local.getMessagesByChatId(chatId);
    final unsyncedMessages = await _local.getUnsyncedMessages();
    final hasNetwork = await GlobalSyncManager.checkInternet();

    print('📊 Message Sync Status for chat $chatId:');
    print('   Local messages: ${localMessages.length}');
    print('   Unsynced messages: ${unsyncedMessages.length}');
    print('   Network: ${hasNetwork ? "✅ Online" : "⛔ Offline"}');
  }

  /// Clear all messages (for testing/logout)
  Future<void> clearAllMessages() async {
    await _local.clearAllMessages();
    print('🧹 Cleared all local messages');
  }
}
