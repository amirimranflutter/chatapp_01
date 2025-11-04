import 'dart:io';

import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/globalSyncManager.dart';
import 'package:flutter/cupertino.dart';
import 'authLocalService.dart';
import 'authService.dart';

class AuthSyncService extends ChangeNotifier {
  final _local = AuthLocalService();
  final _remote = AuthRemoteService();

  Future<String?> syncSignUp({
    required String email,
    required String password,
    required String displayName,
    required File? profileImage,
  }) async {
    final hasInternet = await GlobalSyncManager.checkInternet();
    if (!hasInternet) return "No internet connection";

    try {
      final user = await _remote.signUp(email, password, displayName, profileImage);
      await _local.saveSession(userId: user!.id, email: user.email);
      await _local.saveUser(user);
      return null;
    } catch (e) {
      print("syncSignUp  -->>>$e");
      return e.toString();
    }
  }

  Future<String?> syncSignIn(String email, String password) async {
    final hasInternet = await GlobalSyncManager.checkInternet();
    if (!hasInternet) return "Offline mode — try again later";

    try {
      final user = await _remote.signIn(email, password);
      await _local.saveSession(userId: user!.id, email: user.email);
      await _local.saveUser(user);
      return null;
    } catch (e) {
      print("syncSignIn  -->>>$e");
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _remote.signOut();
    await _local.clearSession();
  }
}
