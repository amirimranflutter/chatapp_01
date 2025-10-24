import 'package:chat_app_cld/cld%20chat/chat_app_01/models/chatRoomModel.dart';
import 'package:hive/hive.dart';

class HiveChatRoomService {
  static const String boxName = 'chatRoomsBox';

  Future<Box> _openBox() async => await Hive.openBox(boxName);

  /// Return all rooms where this user is a participant
  Future<List<ChatRoomModel>> fetchChatRoomsForUser(String userId) async {
    final box = await _openBox();
    final List<ChatRoomModel> allRooms = box.values
        .map((e) => ChatRoomModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return allRooms.where((room) => room.participantIds.contains(userId)).toList();
  }
}
