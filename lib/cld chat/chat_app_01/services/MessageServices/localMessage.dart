// services/MessageServices/hiveMessageService.dart

import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';
import 'package:hive/hive.dart';

class HiveMessageService {
  static const String boxName = 'messages_box';
  Box? _box;

  /// Ensure the box is open before any access
  Future<Box> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
    } else {
      _box = await Hive.openBox(boxName);
    }
    return _box!;
  }

  /// Initialize explicitly (optional but recommended)
  Future<void> init() async => await _ensureBox();

  /// Save a single message to local storage
  Future<void> saveMessage(Message message) async {
    final box = await _ensureBox();
    await box.put(message.id, message.toJson());
    print('💾 Saved message locally: ${message.id}');
  }

  /// Save multiple messages (bulk operation)
  Future<void> saveMessages(List<Message> messages) async {
    final box = await _ensureBox();
    final Map<String, dynamic> entries = {};

    for (var message in messages) {
      entries[message.id] = message.toJson();
    }

    await box.putAll(entries);
    print('💾 Saved ${messages.length} messages locally');
  }

  /// Update an existing message
  Future<void> updateMessage(Message message) async {
    final box = await _ensureBox();
    await box.put(message.id, message.toJson());
    print('✏️ Updated message locally: ${message.id}');
  }

  /// Update message status (sent, delivered, read)
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final box = await _ensureBox();
    final data = box.get(messageId);

    if (data != null) {
      final message = Message.fromJson(Map<String, dynamic>.from(data));
      final updatedMessage = message.copyWith(status: status);
      await box.put(messageId, updatedMessage.toJson());
      print('✅ Updated message status to ${status.name}: $messageId');
    }
  }

  /// Mark message as synced with server
  Future<void> markSynced(String messageId) async {
    final box = await _ensureBox();
    final data = box.get(messageId);

    if (data != null) {
      data['is_synced'] = true;
      await box.put(messageId, data);
      print('✅ Marked message as synced: $messageId');
    }
  }

  /// Get all messages for a specific chat room (sorted by time)
  Future<List<Message>> getMessagesByChatId(String chatId) async {
    final box = await _ensureBox();

    final messages = box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.chatRoomId == chatId && !m.isDeleted)
        .toList();

    // Sort by creation time (oldest first)
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    print('📨 Retrieved ${messages.length} messages for chat: $chatId');
    return messages;
  }

  /// Get a single message by ID
  Future<Message?> getMessageById(String messageId) async {
    final box = await _ensureBox();
    final data = box.get(messageId);

    if (data == null) return null;

    return Message.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get unsynced messages (for offline sync)
  Future<List<Message>> getUnsyncedMessages() async {
    final box = await _ensureBox();

    return box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) => !(msg.toJson()['is_synced'] ?? false))
        .toList();
  }

  /// Get the last message for a chat room
  Future<Message?> getLastMessageForChat(String chatId) async {
    final box = await _ensureBox();

    final messagesForRoom = box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) => msg.chatRoomId == chatId && !msg.isDeleted)
        .toList();

    if (messagesForRoom.isEmpty) return null;

    // Sort descending (newest first)
    messagesForRoom.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return messagesForRoom.first;
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    final box = await _ensureBox();
    final data = box.get(messageId);

    if (data != null) {
      final message = Message.fromJson(Map<String, dynamic>.from(data));
      final deletedMessage = message.copyWith(
        isDeleted: true,
        content: 'This message was deleted',
      );
      await box.put(messageId, deletedMessage.toJson());
      print('🗑️ Soft deleted message: $messageId');
    }
  }

  /// Permanently delete a message from local storage
  Future<void> permanentlyDeleteMessage(String messageId) async {
    final box = await _ensureBox();
    await box.delete(messageId);
    print('🗑️ Permanently deleted message: $messageId');
  }

  /// Delete all messages for a chat room
  Future<void> clearChatMessages(String chatId) async {
    final box = await _ensureBox();
    final messagesToDelete = box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) => msg.chatRoomId == chatId)
        .map((msg) => msg.id)
        .toList();

    await box.deleteAll(messagesToDelete);
    print('🧹 Cleared ${messagesToDelete.length} messages for chat: $chatId');
  }

  /// Get message count for a chat
  Future<int> getMessageCount(String chatId) async {
    final box = await _ensureBox();
    return box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) => msg.chatRoomId == chatId && !msg.isDeleted)
        .length;
  }

  /// Get unread message count for a chat (received but not read)
  Future<int> getUnreadCount(String chatId, String currentUserId) async {
    final box = await _ensureBox();
    return box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) =>
    msg.chatRoomId == chatId &&
        msg.receiverId == currentUserId &&
        msg.status != MessageStatus.read &&
        !msg.isDeleted
    )
        .length;
  }

  /// Search messages by content
  Future<List<Message>> searchMessages(String chatId, String query) async {
    final box = await _ensureBox();

    return box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) =>
    msg.chatRoomId == chatId &&
        msg.content.toLowerCase().contains(query.toLowerCase()) &&
        !msg.isDeleted
    )
        .toList();
  }

  /// Get messages by type (text, image, file, voice)
  Future<List<Message>> getMessagesByType(String chatId, MessageType type) async {
    final box = await _ensureBox();

    return box.values
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) =>
    msg.chatRoomId == chatId &&
        msg.messageType == type &&
        !msg.isDeleted
    )
        .toList();
  }

  /// Debug: Print all messages
  Future<void> printAllMessages() async {
    final box = await _ensureBox();

    if (box.isEmpty) {
      print('📭 No messages found in Hive.');
      return;
    }

    print('📦 All messages in Hive ($boxName):');
    for (var e in box.values) {
      final msg = Message.fromJson(Map<String, dynamic>.from(e));
      print(
        '🗨️ ID: ${msg.id}\n'
            '   Chat Room ID: ${msg.chatRoomId}\n'
            '   Sender: ${msg.senderId}\n'
            '   Receiver: ${msg.receiverId}\n'
            '   Content: ${msg.content}\n'
            '   Status: ${msg.status.name}\n'
            '   Type: ${msg.messageType.name}\n'
            '   Created: ${msg.createdAt}\n'
            '   Deleted: ${msg.isDeleted}\n'
            '   Synced: ${msg.toJson()['is_synced'] ?? false}\n'
            '----------------------------',
      );
    }
  }

  /// Clear all messages (for testing/logout)
  Future<void> clearAllMessages() async {
    final box = await _ensureBox();
    await box.clear();
    print('🧹 All messages cleared from Hive ($boxName)');
  }

  /// Get total message count
  Future<int> getTotalMessageCount() async {
    final box = await _ensureBox();
    return box.length;
  }

  /// Close the box (call on app disposal)
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
      print('📪 Closed messages box');
    }
  }
}
