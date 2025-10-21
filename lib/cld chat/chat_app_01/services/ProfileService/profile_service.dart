import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Utils/showSnackBar.dart';
import '../../models/userModel.dart';
import 'local_profile_repository.dart';
import 'supabase_profile_repository.dart';

class ProfileService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalProfileRepository _localRepo = LocalProfileRepository();
  final SupabaseProfileRepository _remoteRepo = SupabaseProfileRepository();

  UserModel? _currentProfile;
  UserModel? get currentProfile => _currentProfile;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SupabaseClient get supabase => _supabase;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  /// ✅ Load current user profile — prefers local first, then syncs from remote
  Future<void> loadCurrentUserProfile(BuildContext context, {bool forceRefresh = false}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ [ProfileService] User ID is null.');
      return;
    }

    try {
      // Step 1: Try loading from local Hive
      final localProfile = await _localRepo.getProfile(userId, context);
      if (localProfile != null && !forceRefresh) {
        _currentProfile = localProfile;
        notifyListeners();
      }

      // Step 2: Fetch from Supabase (remote)
      final remoteProfile = await _remoteRepo.getProfile(userId, context);
      if (remoteProfile != null) {
        _currentProfile = remoteProfile;
        await _localRepo.saveProfile(remoteProfile, context); // Sync locally
        print('✅ Profile synced from Supabase');
        notifyListeners();
      } else {
        print('⚠️ No profile found on Supabase.');
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      SnackbarService.showError(context, 'Error loading profile: $e');
    }
  }

  /// ✅ Update display name locally and remotely
  Future<void> updateDisplayName(String name, BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (_currentProfile == null) return;

      // Step 1: Update local
      final updatedProfile = UserModel(
        id: _currentProfile!.id,
        displayName: name,
        email: _currentProfile!.email,
        avatarUrl: _currentProfile!.avatarUrl,
        createdAt: _currentProfile!.createdAt,
      );
      await _localRepo.saveProfile(updatedProfile, context);
      _currentProfile = updatedProfile;
      notifyListeners();

      // Step 2: Update remote
      await _remoteRepo.updateDisplayName(userId, name, context);
      print('✅ Display name updated both locally and remotely');
    } catch (e) {
      print('❌ Error updating display name: $e');
      SnackbarService.showError(context, 'Failed to update name: $e');
    }
  }

  /// ✅ Update avatar (supports both local + remote sync)
  Future<void> updateAvatar(File avatarFile, BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _currentProfile == null) return;

    try {
      final path = avatarFile.path;

      // Step 1: Update local avatar
      final updatedProfile = UserModel(
        id: _currentProfile!.id,
        displayName: _currentProfile!.displayName,
        email: _currentProfile!.email,
        avatarUrl: path,
        createdAt: _currentProfile!.createdAt,
      );
      await _localRepo.saveProfile(updatedProfile, context);
      _currentProfile = updatedProfile;
      notifyListeners();

      // Step 2: Upload to Supabase and update remote
      await _remoteRepo.updateAvatar(userId, path, context);
      print('✅ Avatar updated both locally and remotely');
    } catch (e) {
      print('❌ Error updating avatar: $e');
      SnackbarService.showError(context, 'Failed to update avatar: $e');
    }
  }

  /// ✅ Manually trigger profile sync (e.g., on reconnect or app start)
  Future<void> syncProfile(BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || _currentProfile == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      // Save local profile to remote
      await _remoteRepo.saveProfile(_currentProfile!, context);
      print('✅ Local profile synced to Supabase.');
    } catch (e) {
      print('❌ Error syncing profile: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
