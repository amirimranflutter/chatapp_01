import 'dart:io';
import 'package:chat_app_cld/cld%20chat/chat_app_01/Utils/showSnackBar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//this
class ProfileService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  get supabase => _supabase;

  Map<String, dynamic>? _currentProfile;
  Map<String, dynamic>? get currentProfile => _currentProfile;

  Map<String, dynamic>? _otherProfile;
  Map<String, dynamic>? get otherProfile => _otherProfile;

  /// ✅ Load either current or other user profile
  Future<void> loadUserProfile({String? userId, bool isOtherUser = false}) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      print('⚠️ No authenticated user found');
      return;
    }

    try {
      final targetUserId = userId ?? currentUserId;

      final profile = await _supabase
          .from('profiles')
          .select('id,display_name,avatar_url,email')
          .eq('id', targetUserId)
          .single();

      if (isOtherUser) {
        _otherProfile = profile;
      } else {
        _currentProfile = profile;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
    }
  }

  /// ✅ Update display name for current user
  Future<void> updateDisplayName(String name, BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ User id is null in updateDisplayName');
      return;
    }
    try {
      await _supabase
          .from('profiles')
          .update({'display_name': name})
          .eq('id', userId);

      SnackbarService.showSuccess(context, "Profile successfully updated");
      _currentProfile?['display_name'] = name;
      notifyListeners();
    } catch (e) {
      SnackbarService.showError(context, 'Failed to update profile: $e');
      debugPrint('❌ Error updating profile: $e');
    }
  }

  /// ✅ Update avatar
  Future<void> updateAvatar(File avatarFile, BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ User id is null in updateAvatar');
      return;
    }

    try {
      final path = 'avatar/$userId.png';
      await _supabase.storage
          .from('avatars')
          .upload(path, avatarFile, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      SnackbarService.showSuccess(context, "Avatar successfully updated");
      _currentProfile?['avatar_url'] = publicUrl;
      notifyListeners();
    } catch (e) {
      SnackbarService.showError(context, 'Error updating avatar: $e');
      debugPrint('❌ Error in updateAvatar: $e');
    }
  }
}
