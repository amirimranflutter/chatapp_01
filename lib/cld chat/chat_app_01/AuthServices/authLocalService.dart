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
  }

  Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(_userBox);
    await box.put('currentUser', user);
  }

  bool isLoggedIn() => Hive.box(_sessionBox).get('userId') != null;
  String? getUserId() => Hive.box(_sessionBox).get('userId');
  String? getToken() => Hive.box(_sessionBox).get('token');

  Future<UserModel?> getLocalUser() async {
    final box = Hive.box<UserModel>(_userBox);
    return box.get('currentUser');
  }

  Future<void> clearSession() async {
    await Hive.box(_sessionBox).clear();
    await Hive.box<UserModel>(_userBox).clear();
  }
}
