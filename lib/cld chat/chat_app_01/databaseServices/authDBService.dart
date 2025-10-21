import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class HiveAuthService extends ChangeNotifier {
  static const String _sessionBoxName = 'session';

  /// ✅ Open session box (call in main.dart before runApp)
  static Future<void> init() async {
    await Hive.openBox(_sessionBoxName);
  }

  /// ✅ Save user session after login
  Future<void> saveSession({
    required String userId,
    required String email,
    String? token,
  }) async {
    final sessionBox = Hive.box(_sessionBoxName);
    await sessionBox.put('userId', userId);
    await sessionBox.put('email', email);
    if (token != null) {
      await sessionBox.put('token', token);
    }
  }

  /// ✅ Check if user is logged in
  bool isLoggedIn() {
    final sessionBox = Hive.box(_sessionBoxName);
    return sessionBox.get('userId') != null;
  }

  /// ✅ Get current user ID
  String? getUserId() {
    final sessionBox = Hive.box(_sessionBoxName);
    return sessionBox.get('userId');
  }

  /// ✅ Get stored token
  String? getToken() {
    final sessionBox = Hive.box(_sessionBoxName);
    return sessionBox.get('token');
  }

  /// ✅ Clear session on logout
  Future<void> clearSession() async {
    final sessionBox = Hive.box(_sessionBoxName);
    await sessionBox.clear();
  }
}
