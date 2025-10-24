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
      'text': message.text,
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
  Future<List<MessageModel>> getMessages(String userId, String contactId) async {

    final box = await _ensureBox();
    final all = box.values;

    return all
        .where((item) =>
    (item['senderId'] == userId && item['receiverId'] == contactId) ||
        (item['senderId'] == contactId && item['receiverId'] == userId))
        .map((m) => MessageModel(
      id: m['id'],
      senderId: m['senderId'],
      chatId: m['chatId'],
      text: m['text'],
      createdAt: DateTime.parse(m['createdAt']),
      isSynced: m['isSynced'],
    ))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

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
      text: m['text'],
      createdAt: DateTime.parse(m['createdAt']),
      isSynced: m['isSynced'],
    ))
        .toList();
  }

  /// Return the most recent message for a given chat room
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
}
