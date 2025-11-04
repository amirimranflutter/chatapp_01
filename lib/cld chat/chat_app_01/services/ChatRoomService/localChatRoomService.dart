import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class HiveChatRoomService {
  static const String boxName = 'chatRoomsBox';

  Future<Box> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Return all rooms where this user is a participant
  Future<List<ChatRoomModel>> fetchChatRoomsForUser(String userId) async {
    final box = await _openBox();
    final allRooms = box.values
        .map((e) => ChatRoomModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return allRooms.where((room) => room.participantIds.contains(userId)).toList();
  }

  /// Find an existing private chat room by participants, or create a new one
  Future<String> findOrCreateChatRoom(String userAId, String userBId) async {
    print('finedOrCreatedRoom');
    final box = await _openBox();
    final rooms = box.values
        .map((e) => ChatRoomModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // Find an existing private chat between the two users
    ChatRoomModel? found;
    try {
      found = rooms.firstWhere((room) =>
      room.type == 'private' &&
          room.participantIds.contains(userAId) &&
          room.participantIds.contains(userBId) &&
          room.participantIds.length == 2,
      );
    } catch (e) {
      found = null;
    }

    if (found != null) return found.id;

    // Otherwise create new
    print("Otherwise create new");
    final chatId = const Uuid().v4();
    final newRoom = ChatRoomModel(
      id: chatId,
      participantIds: [userAId, userBId],
      type: 'private',
      createdAt: DateTime.now(),
    );

    await box.put(chatId, newRoom.toMap());
    return chatId;
  }
  Future<void> printAllChatRooms() async {
    final box = await _openBox();
    if (box.isEmpty) {
      print('📦 No chat rooms in Hive.');
      return;
    }

    print('📦 All chat rooms in Hive ($boxName):');
    for (var room in box.values) {
      final chatRoom = ChatRoomModel.fromMap(Map<String, dynamic>.from(room));
      print('🆔 ID: ${chatRoom.id}');
      print('Type: ${chatRoom.type}');
      print('Name: ${chatRoom.name ?? "N/A"}');
      print('Participants: ${chatRoom.participantIds}');
      print('Created At: ${chatRoom.createdAt}');
      print('------------------------');
    }
  }
  Future<void> clearAllChatRooms() async {
    final box = await _openBox();
    await box.clear();
    print('🧹 All chat rooms cleared from Hive ($boxName)');
  }
}
