import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/userModel.dart';

class AuthLocalService extends ChangeNotifier {
  static const _sessionBox = 'session';
  static const _userBox = 'userBox';

  /// Initialize local Hive boxes
  static Future<void> init() async {
    await Hive.openBox(_sessionBox);
    await Hive.openBox<UserModel>(_userBox);
  }

  Future<void> saveSession({
    required String userId,
    required String email,
    String? token,
  }) async {
    final box = Hive.box(_sessionBox);
    await box.putAll({
      'userId': userId,
      'email': email,
      if (token != null) 'token': token,
    });
    print('✅ Session saved with userId: $userId');
  }

  // ✅ FIX 1: Save user with userId as key (matching retrieval)
  Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(_userBox);
    await box.put(user.id, user);
    print('✅ User saved with key: ${user.id}');

    // Verify it was saved
    final savedUser = box.get(user.id);
    if (savedUser != null) {
      print('✅ Verification: User exists in box');
    } else {
      print('❌ ERROR: User NOT found after saving!');
    }
  }

  UserModel? getCurrentUser() {
    final userBox = Hive.box<UserModel>(_userBox);
    final session = Hive.box(_sessionBox);

    final userId = session.get('userId');

    print('🔍 Debug - userId from session: $userId');
    print('🔍 Debug - All keys in userBox: ${userBox.keys.toList()}');

    if (userId == null) {
      print('❌ No userId in session');
      return null;
    }

    final currentUser = userBox.get(userId);

    return currentUser;
  }

  // ✅ FIX 3: Use same method for consistency
  Future<UserModel?> getLocalUser() async {
    return getCurrentUser(); // Use the same method
  }

  bool isLoggedIn() {
    final sessionBox = Hive.box(_sessionBox);
    final userBox = Hive.box<UserModel>(_userBox);

    final userId = sessionBox.get('userId');
    if (userId == null || userId.toString().isEmpty) {
      return false;
    }

    // ✅ Verify user data actually exists
    final user = userBox.get(userId);
    return user != null;
  }

  String? getUserId() => Hive.box(_sessionBox).get('userId');
  String? getToken() => Hive.box(_sessionBox).get('token');

  Future<void> clearSession() async {
    await Hive.box(_sessionBox).clear();
    await Hive.box<UserModel>(_userBox).clear();
    notifyListeners();
  }
}
