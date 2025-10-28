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

  /// Initialize explicitly (optional)
  Future<void> init() async => await _ensureBox();

  /// Save a message locally (offline-safe)
  Future<void> saveMessage(MessageModel message) async {
    final box = await _ensureBox();
    await box.put(message.id, {
      'id': message.id,
      'senderId': message.senderId,
      'chatId': message.chatId,
      'content': message.content,
      'createdAt': message.createdAt.toIso8601String(),
      'isSynced': message.isSynced,
    });
  }

  /// Mark message as synced when uploaded successfully
  Future<void> markSynced(String messageId) async {
    final box = await _ensureBox();
    final data = box.get(messageId);
    if (data != null) {
      data['isSynced'] = true;
      await box.put(messageId, data);
    }
  }

  /// Load messages between two users


  /// Get offline pending messages
  Future<List<MessageModel>> getUnsyncedMessages() async {
    final box = await _ensureBox();
    final all = box.values;

    return all
        .where((item) => item['isSynced'] == false)
        .map((m) => MessageModel(
      id: m['id'],
      senderId: m['senderId'],
      chatId: m['chatId'],
      content: m['text'],
      createdAt: DateTime.parse(m['createdAt']),
      isSynced: m['isSynced'],
    ))
        .toList();
  }

  // Return the most recent message for a given chat room
  Future<MessageModel?> fetchLastMessage(String chatId) async {
    final box = await _ensureBox();

    final messagesForRoom = box.values
        .map((e) => MessageModel.fromJson(Map<String, dynamic>.from(e)))
        .where((msg) => msg.chatId == chatId)
        .toList();

    if (messagesForRoom.isEmpty) return null;

    messagesForRoom.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return messagesForRoom.first;
  }



  Future<void> printAllMessages() async {
    final box = await Hive.openBox('messages_box');

    if (box.isEmpty) {
      print('📭 No messages found in Hive.');
      return;
    }

    print('📦 All messages in Hive (messages_box):');
    for (var e in box.values) {
      final msg = MessageModel.fromJson(Map<String, dynamic>.from(e));
      print(
        '🗨️ ID: ${msg.id}\n'
            'Chat ID: ${msg.chatId}\n'
            'Sender ID: ${msg.senderId}\n'
            'Content: ${msg.content}\n'
            'Created At: ${msg.createdAt}\n'
            'Synced: ${msg.isSynced}\n'
            '----------------------------',
      );
    }
  }

  Future<void> clearAllMessages() async {
    final box = await Hive.openBox(boxName);
    await box.clear(); // ✅ deletes all messages inside
    print('🧹 All messages cleared from Hive ($boxName)');
  }

}
