// services/chatRoomServices/hiveChatRoomService.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../models/chatRoomModel.dart';

class HiveChatRoomService {
  static const String boxName = 'chatRoomsBox';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Fetch all chat rooms for a user from local storage
  Future<List<ChatRoom>> fetchChatRoomsForUser(String userId) async {
    final box = await _openBox();
    final allRooms = box.values
        .map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Filter rooms where user is participant1 or participant2
    return allRooms.where((room) =>
    room.participant1Id == userId || room.participant2Id == userId
    ).toList();
  }

  /// Find existing chat room or create new one (matches Supabase function logic)
  Future<String> findOrCreateChatRoom(String user1Id, String user2Id) async {
    print('🔍 Finding or creating chat room for: $user1Id <-> $user2Id');
    final box = await _openBox();

    // Sort IDs to ensure consistent ordering (smaller ID first)
    final smallerId = user1Id.compareTo(user2Id) < 0 ? user1Id : user2Id;
    final largerId = user1Id.compareTo(user2Id) < 0 ? user2Id : user1Id;

    // Search for existing room with these participants
    final rooms = box.values
        .map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    ChatRoom? existingRoom;
    try {
      existingRoom = rooms.firstWhere(
            (room) =>
        room.participant1Id == smallerId &&
            room.participant2Id == largerId,
      );
    } catch (e) {
      existingRoom = null;
    }

    if (existingRoom != null) {
      print('✅ Found existing room: ${existingRoom.id}');
      return existingRoom.id;
    }

    // Create new room
    print('📝 Creating new chat room...');
    final chatId = const Uuid().v4();
    final now = DateTime.now();

    final newRoom = ChatRoom(
      id: chatId,
      participant1Id: smallerId,
      participant2Id: largerId,
      createdAt: now,
      updatedAt: now,
    );

    await box.put(chatId, newRoom.toJson());
    print('✅ Created new room: $chatId');
    return chatId;
  }

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoomById(String chatId) async {
    final box = await _openBox();
    final roomData = box.get(chatId);

    if (roomData == null) return null;

    return ChatRoom.fromJson(Map<String, dynamic>.from(roomData));
  }

  /// Update chat room's last message info
  Future<void> updateLastMessage(String chatId, String message, DateTime timestamp) async {
    final box = await _openBox();
    final roomData = box.get(chatId);

    if (roomData != null) {
      final room = ChatRoom.fromJson(Map<String, dynamic>.from(roomData));
      final updatedRoom = ChatRoom(
        id: room.id,
        participant1Id: room.participant1Id,
        participant2Id: room.participant2Id,
        createdAt: room.createdAt,
        updatedAt: DateTime.now(),
        lastMessageContent: message,
        lastMessageAt: timestamp,
      );

      await box.put(chatId, updatedRoom.toJson());
      print('✅ Updated last message for room: $chatId');
    }
  }

  /// Save/update a chat room
  Future<void> saveChatRoom(ChatRoom room) async {
    final box = await _openBox();
    await box.put(room.id, room.toJson());
    print('💾 Saved chat room: ${room.id}');
  }

  /// Delete a chat room
  Future<void> deleteChatRoom(String chatId) async {
    final box = await _openBox();
    await box.delete(chatId);
    print('🗑️ Deleted chat room: $chatId');
  }

  /// Print all chat rooms (for debugging)
  Future<void> printAllChatRooms() async {
    final box = await _openBox();
    if (box.isEmpty) {
      print('📦 No chat rooms in Hive.');
      return;
    }

    print('📦 All chat rooms in Hive ($boxName):');
    for (var roomData in box.values) {
      final room = ChatRoom.fromJson(Map<String, dynamic>.from(roomData));
      print('🆔 ID: ${room.id}');
      print('👤 Participant 1: ${room.participant1Id}');
      print('👤 Participant 2: ${room.participant2Id}');
      print('💬 Last Message: ${room.lastMessageContent ?? "N/A"}');
      print('🕐 Last Message At: ${room.lastMessageAt ?? "N/A"}');
      print('📅 Created: ${room.createdAt}');
      print('📅 Updated: ${room.updatedAt}');
      print('------------------------');
    }
  }

  /// Clear all chat rooms (for testing)
  Future<void> clearAllChatRooms() async {
    final box = await _openBox();
    await box.clear();
    print('🧹 All chat rooms cleared from Hive ($boxName)');
  }

  /// Get count of chat rooms
  Future<int> getChatRoomCount() async {
    final box = await _openBox();
    return box.length;
  }
}
