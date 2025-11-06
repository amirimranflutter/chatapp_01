import 'dart:io';

import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:flutter/cupertino.dart';
import '../models/userModel.dart';
import 'authLocalService.dart';
import 'authService.dart';

class AuthSyncService extends ChangeNotifier {
  final _local = AuthLocalService();
  final _remote = AuthRemoteService();

  UserModel? getCurrentUser() {
    return _local.getCurrentUser();
  }
  String? getUserId() {
    return _local.getUserId();
  }
  // ✅ Also add isLoggedIn for convenience
  bool isLoggedIn() {
    return _local.isLoggedIn();
  }

  Future<String?> syncSignUp({
    required String email,
    required String password,
    required String displayName,
    required File? profileImage,
  }) async {
    final hasInternet = await GlobalSyncManager.checkInternet();
    if (!hasInternet) return "No internet connection";

    try {
      final user = await _remote.signUp(
        email,
        password,
        displayName,
        profileImage,
      );
      await _local.saveSession(userId: user!.id, email: user.email);
      await _local.saveUser(user);
      return null;
    } catch (e) {
      print("syncSignUp  -->>>$e");
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _local.clearSession();
    notifyListeners();
  }

  Future<String?> syncSignIn(String email, String password) async {
    final hasInternet = await GlobalSyncManager.checkInternet();
    if (!hasInternet) return "Offline mode — try again later";

    try {
      final user = await _remote.signIn(email, password);

      // Step 1: Save session
      await _local.saveSession(userId: user!.id, email: user.email);
      print('✅ Step 1: Session saved');

      // Step 2: Save user
      await _local.saveUser(user);
      print('✅ Step 2: User saved');

      // Step 3: Verify data was saved
      await Future.delayed(
        Duration(milliseconds: 100),
      ); // Give Hive time to write
      final verifyUser = _local.getCurrentUser();
      if (verifyUser == null) {
        print('❌ VERIFICATION FAILED: User is null after save');
        return "Failed to save user data";
      }
      print('✅ Step 3: Verification passed');

      return null; // Success
    } catch (e) {
      print("syncSignIn -->>>$e");
      return e.toString();
    }
  }
}
