// services/local/hive_message_service.dart
import 'package:chat_app_cld/cld%20chat/chat_app_01/models/messageModel.dart';
import 'package:hive/hive.dart';

class HiveMessageService {
  static const String boxName = 'messages_box';
  late Box _box;

  /// Initialize Hive box
  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  /// Save a message locally (offline-safe)
  Future<void> saveMessage(MessageModel message) async {
    await _box.put(message.id, {
      'id': message.id,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'text': message.text,
      'createdAt': message.createdAt.toIso8601String(),
      'isSynced': message.isSynced,
    });
  }

  /// Mark message as synced when uploaded successfully
  Future<void> markSynced(String messageId) async {
    final data = _box.get(messageId);
    if (data != null) {
      data['isSynced'] = true;
      await _box.put(messageId, data);
    }
  }

  /// Load messages between two users
  List<MessageModel> getMessages(String userId, String contactId) {
    final all = _box.values;
    return all
        .where((item) =>
    (item['senderId'] == userId && item['receiverId'] == contactId) ||
        (item['senderId'] == contactId && item['receiverId'] == userId))
        .map((m) {
      return MessageModel(
        id: m['id'],
        senderId: m['senderId'],
        receiverId: m['receiverId'],
        text: m['text'],
        createdAt: DateTime.parse(m['createdAt']),
        isSynced: m['isSynced'],
      );
    })
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get offline pending messages
  List<MessageModel> getUnsyncedMessages() {
    final all = _box.values;
    return all
        .where((item) => item['isSynced'] == false)
        .map((m) {
      return MessageModel(
        id: m['id'],
        senderId: m['senderId'],
        receiverId: m['receiverId'],
        text: m['text'],
        createdAt: DateTime.parse(m['createdAt']),
        isSynced: m['isSynced'],
      );
    })
        .toList();
  }
}
