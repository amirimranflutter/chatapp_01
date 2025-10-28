import 'package:chat_app_cld/cld%20chat/chat_app_01/services/MessageServices/remoteMessage.dart';
import '../../models/messageModel.dart';
import 'localMessage.dart';

class MessageRepository {
  final HiveMessageService _local;
  final SupabaseMessageService _remote;

  MessageRepository(this._local, this._remote);

  /// Send a message: save locally, then try to sync remotely
  Future<void> sendMessage(MessageModel message) async {
    await _local.saveMessage(message);

    try {
      await _remote.uploadMessage(message);
      await _local.markSynced(message.id);
    } catch (e) {
      // remains unsynced until reconnection
      print("⚠️ Message sync failed: $e");
    }
  }

  /// Load chat from local storage (async now)
  Future<List<MessageModel>> getLocalMessages(String chatId) async {
    return await _local.getMessagesByChatId(chatId);
  }

  /// Force remote → local sync (optional)
  Future<void> syncFromServer(String userId, String contactId) async {
    final remoteMessages = await _remote.fetchMessages(userId, contactId);

    for (final msg in remoteMessages) {
      await _local.saveMessage(msg);
    }
  }

  /// Sync unsent messages (used when internet returns)
  Future<void> syncPending() async {
    final unsynced = await _local.getUnsyncedMessages();

    for (final msg in unsynced) {
      try {
        await _remote.uploadMessage(msg);
        await _local.markSynced(msg.id);
      } catch (e) {
        print("⚠️ Failed to sync message ${msg.id}: $e");
      }
    }
  }

  /// Fetch last message for a given chat room
  Future<MessageModel?> fetchLastMessage(String chatId) async {
    return await _local.fetchLastMessage(chatId);
  }
}
